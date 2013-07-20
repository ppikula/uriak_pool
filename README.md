Main features
=============

 * Graceful handling of riak nodes starts and shutdowns
 * simultaneous work with different riak clusters
 * **parse_transform** generation for interfaces from the client code
 * simple configuring using erlang configuration files
 * reconfiguration in runtime
 * tested in production at Unison Technologies

Getting started
===============

Building
--------

You can build this software with **rebar** tool:
```shell
rebar get-deps && rebar compile
```

Usage as rebar dependency:

```erlang
{riak_pool, ".*", {git, "git@github.com:unisontech/uriak_pool.git", "master"}}
```

**Important note:** by default, all dependencies are fetched
from github.com/unisontech repositories.
You can change this setup in _rebar.config_ file.
But if you do so (e.g. in order to switch to the newest version of riakc),
something might not work properly.

Configuration
-------------

* You can configure **riak_pool** with a configuration file of your release.

See configuration format description and example [here](etc/app.config)

* You also can reconfigure **riak_pool** in runtime with:

```erlang

riak_pool_clusters_sup:start_cluster/3
riak_pool_clusters_sup:stop_cluster/1

riak_pool_cluster_sup:start_pool/3
riak_pool_cluster_sup:stop_pool/2
```
