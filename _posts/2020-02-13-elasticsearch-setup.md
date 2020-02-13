---
title: Elasticsearch 7.5安装及启动
date: 2020-02-13 21:13:52
category: Elasticsearch
tags: Elasticsearch
layout: post

---

## 环境准备

* Elasticsearch 7.5需要Java 11的环境依赖
* Elasticsearch 7.5的安装包中，已经打包了一个编译好的OpenJDK（Elasticsearch 7.5.1对应版本是openjdk 13.0.1 2019-10-15）
* 如需要使用本地的Java（[LTS版本](https://www.oracle.com/technetwork/java/eol-135779.html)），也可以修改JAVA_HOME的环境变量，同时删除安装包中已打包好的JVM目录；或增加ES的Java环境变量，并修改启动脚本
* 测试环境：腾讯云CVM

## 安装

* 下载安装包并解压
根据相应的操作系统版本，下载安装包

```sh
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.5.2-linux-x86_64.tar.gz
tar -xzf elasticsearch-7.5.2-linux-x86_64.tar.gz
cd elasticsearch-7.5.2/
```

* 不修改任何配置，从命令行以非root用户启动Elasticsearch

```sh
./bin/elasticsearch
```

* 检查Elasticsearch状态

```sh
[root@VM_0_6_centos config]# curl http://127.0.0.1:9200
{
  "name" : "VM_0_6_centos",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "n_jjqcOESl6_uviSTeT9sQ",
  "version" : {
    "number" : "7.5.1",
    "build_flavor" : "default",
    "build_type" : "tar",
    "build_hash" : "3ae9ac9a93c95bd0cdc054951cf95d88e1e18d96",
    "build_date" : "2019-12-16T22:57:37.835892Z",
    "build_snapshot" : false,
    "lucene_version" : "8.3.0",
    "minimum_wire_compatibility_version" : "6.8.0",
    "minimum_index_compatibility_version" : "6.0.0-beta1"
  },
  "tagline" : "You Know, for Search"
}
```

## 启动常见问题及解决办法

### 以root用户启动报错

```sh
[root@VM_0_6_centos bin]# ./elasticsearch
OpenJDK 64-Bit Server VM warning: Option UseConcMarkSweepGC was deprecated in version 9.0 and will likely be removed in a future release.
[2020-02-13T16:53:41,823][WARN ][o.e.b.ElasticsearchUncaughtExceptionHandler] [VM_0_6_centos] uncaught exception in thread [main]
org.elasticsearch.bootstrap.StartupException: java.lang.RuntimeException: can not run elasticsearch as root
 at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:163) ~[elasticsearch-7.5.1.jar:7.5.1]
 at org.elasticsearch.bootstrap.Elasticsearch.execute(Elasticsearch.java:150) ~[elasticsearch-7.5.1.jar:7.5.1]
 at org.elasticsearch.cli.EnvironmentAwareCommand.execute(EnvironmentAwareCommand.java:86) ~[elasticsearch-7.5.1.jar:7.5.1]
 at org.elasticsearch.cli.Command.mainWithoutErrorHandling(Command.java:125) ~[elasticsearch-cli-7.5.1.jar:7.5.1]
 at org.elasticsearch.cli.Command.main(Command.java:90) ~[elasticsearch-cli-7.5.1.jar:7.5.1]
 at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:115) ~[elasticsearch-7.5.1.jar:7.5.1]
 at org.elasticsearch.bootstrap.Elasticsearch.main(Elasticsearch.java:92) ~[elasticsearch-7.5.1.jar:7.5.1]
Caused by: java.lang.RuntimeException: can not run elasticsearch as root
 at org.elasticsearch.bootstrap.Bootstrap.initializeNatives(Bootstrap.java:105) ~[elasticsearch-7.5.1.jar:7.5.1]
 at org.elasticsearch.bootstrap.Bootstrap.setup(Bootstrap.java:172) ~[elasticsearch-7.5.1.jar:7.5.1]
 at org.elasticsearch.bootstrap.Bootstrap.init(Bootstrap.java:349) ~[elasticsearch-7.5.1.jar:7.5.1]
 at org.elasticsearch.bootstrap.Elasticsearch.init(Elasticsearch.java:159) ~[elasticsearch-7.5.1.jar:7.5.1]
 ... 6 more
```

从上面的报错信息可以看到是以 root 用户启动 elasticsearch 引起的，需要新增一个用户，并把 elasticsearch-7.5.2 目录的权限赋予该用户

```sh
[root@VM_0_6_centos bin]# adduser elasticsearch
[root@VM_0_6_centos bin]# passwd elasticsearch
[root@VM_0_6_centos bin]# cd ../..
[root@VM_0_6_centos bin]# chown -R elasticsearch elasticsearch-7.5.1
[root@VM_0_6_centos bin]# chgrp -R elasticsearch elasticsearch-7.5.1
```

增加完用户后，切换到该用户，并进入到 elasticsearch-7.5.1 目录，再次启动 elasticsearch

### bootstrap checks失败

*   开发环境

    如果在es的配置中没有配置network.host来指定一个可用的IP地址的话，默认情况下，就绑定到localhost上，此时es会认为用户只是在开发环境下使用es，基于开箱即用的原则，虽然es此时也会进行bootstrap checks，来检查用户的配置是否与es设定的安全值相匹配，如下：
    -   如果匹配，则不会有warnning信息，此时es正常启动；
    -   如果不匹配，则会有warnning信息，但因为是开发环境，es依然会正常启动；

*   生产环境

    一旦用户配置了network.host来指定一个可用的非loopback地址，那么es就会认为用户此时是在生产环境下启动es，同样会进行检查，但一旦检查不通过，直接会将前面的warnning提升为error，所以此时es会启动失败。

```sh
ERROR: [2] bootstrap checks failed
[1]: max file descriptors [4096] for elasticsearch process is too low, increase to at least [65536]
[2]: max number of threads [1024] for user [elasticsearch] is too low, increase to at least [2048]
[3]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
[4]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured
[2020-02-11T22:10:46,068][INFO ][o.e.n.Node ] [VM_0_6_centos] stopping ...
[2020-02-11T22:10:46,100][INFO ][o.e.n.Node ] [VM_0_6_centos] stopped
[2020-02-11T22:10:46,101][INFO ][o.e.n.Node ] [VM_0_6_centos] closing ...
[2020-02-11T22:10:46,140][INFO ][o.e.n.Node ] [VM_0_6_centos] closed
[2020-02-11T22:10:46,145][INFO ][o.e.x.m.p.NativeController] [VM_0_6_centos] Native controller process has stopped - no new native processes can be started
```

#### 修改最大文件描述符数量

可通过命令 **ulimit -n** 查看当前的最大文件描述符数量

* 临时修改

```sh
ulimit -n 65535
```

* 永久修改
修改 **/etc/security/limits.conf** 配置

```conf
* soft nofile 65535
* hard nofile 65535
```

#### 修改最大线程数量

可通过命令 **ulimit -u** 查看当前的最大线程数量

* 临时修改

```sh
ulimit -u 65535
```

* 永久修改
修改 **/etc/security/limits.conf** 配置

```conf
* soft nproc 2048
* hard nproc 2048
```

#### 修改最大虚拟内存容量

可通过命令 **sysctl vm.max_map_count** 查看当前的最大线程数量

* 临时修改

```sh
sysctl -w vm.max_map_count=262144
```

* 永久修改（重启系统后才生效）

修改 **/etc/sysctl.conf** 配置

```conf
vm.max_map_count=262144
```

#### 修改节点中的配置文件

* discovery.seed_hosts

> 如果要在其他主机上形成包含节点的群集，则必须使用discovery.seed_hosts设置提供群集中其他节点的列表，这些节点符合主要条件且可能是实时且可联系的，以便为发现过程设定种子。 此设置通常应包含群集中所有符合主节点的节点的地址。 此设置包含主机数组或逗号分隔的字符串。 每个值应采用host：port或host的形式（其中port默认为设置transport.profiles.default.port，如果未设置则返回transport.port）。 请注意，必须将IPv6主机置于括号内。 此设置的默认值为127.0.0.1，[:: 1]。

IPv6的回环地址是 **0:0:0:0:0:0:0:1**，简写成 **::1**。 IPv4的回环地址是 **127.0.0.1** 。针对单机的应用，可以使用默认的配置 **["127.0.0.1", "[::1]"]** ，针对生产环境，根据实际的主机IP和端口来配置。

* cluster.initial_master_nodes

> 在生产模式下启动全新集群时，必须明确列出符合条件的节点的名称或IP地址，这些节点的投票应在第一次选举中计算。 使用cluster.initial_master_nodes设置设置此列表

## 参考
1. [Elasticsearch官方安装说明](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup.html)
2. [Elasticsearch官方安装说明-重要配置](https://www.elastic.co/guide/en/elasticsearch/reference/7.0/discovery-settings.html)
3. [IPv6详解](https://www.cnblogs.com/qiangupc/p/4090122.html)
4. [Elasticsearch 7.x 生产配置](https://blog.csdn.net/chengyuqiang/article/details/89841544)
5. [Elasticsearch 启动分析与问题解决 -bootstrap](https://blog.51cto.com/xpleaf/2327317)
