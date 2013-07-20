%%% Copyright 2012-2013 Unison Technologies, Inc.
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.

-module(riak_pool).

-export([
         with_worker/2, with_worker/3, with_worker/4,
         with_connection/2, with_connection/3, with_connection/4,
         get_worker/1, free_worker/1,
         connection/1
        ]).

-type connection() :: pid().
-type pool_name() :: atom().
-type worker() :: {pool_name(), connection()}.

-spec connection(worker()) -> connection().
connection({_Pool, Conn}) ->
    Conn.

with_connection(ClusterName, Fun)        -> do_with_connection(ClusterName, Fun).
with_connection(ClusterName, Fun, Args)  -> do_with_connection(ClusterName, {Fun, Args}).
with_connection(ClusterName, M, F, Args) -> do_with_connection(ClusterName, {M, F, Args}).

with_worker(ClusterName, Fun)        -> do_with_worker(ClusterName, Fun).
with_worker(ClusterName, Fun, Args)  -> do_with_worker(ClusterName, {Fun, Args}).
with_worker(ClusterName, M, F, Args) -> do_with_worker(ClusterName, {M, F, Args}).

do_with_worker(ClusterName, Fun) ->
    case get_worker(ClusterName) of
        {error, _W} = Error -> Error;
        {ok, Worker} ->
            try
                apply_worker_operation(Worker, Fun)
            after
                riak_pool:free_worker(Worker)
            end
    end.

do_with_connection(ClusterName, Fun) ->
    case get_worker(ClusterName) of
        {error, _W} = Error -> Error;
        {ok, Worker} ->
            try
                apply_worker_operation(connection(Worker), Fun)
            after
                riak_pool:free_worker(Worker)
            end
    end.

apply_worker_operation(Worker, Fun) when is_function(Fun, 1) ->
    Fun(Worker);
apply_worker_operation(Worker, {M, F, A}) ->
    apply(M, F, [Worker | A]);
apply_worker_operation(Worker, {F, A}) ->
    apply(F, [Worker | A]).


-spec get_worker(ClusterName :: atom()) -> worker().
get_worker(ClusterName) ->
    do_get_worker(riak_pool_balancer:get_pool(ClusterName)).

do_get_worker({error, _W} = Error) -> Error;
do_get_worker(Pool) ->
    case poolboy:checkout(Pool) of
        Conn when is_pid(Conn) ->
            {ok, {Pool, Conn}};
        Error ->
            {error, {pool_checkout, Error}}
    end.

-spec free_worker(worker()) -> ok.
free_worker({Pool, Conn}) ->
    poolboy:checkin(Pool, Conn).
