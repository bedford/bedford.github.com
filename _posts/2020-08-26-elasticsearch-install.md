---
title: ES 安装部署及注意事项
date: 2020-08-26 09:49:52
category: 大数据
tags: Centos 7, elasticsearch, ES
layout: post
---

## 一、节点职责单一、各施其职

ES的配置文件中有两个参数用于设置该节点的职责：
* node.master
* node.data

数据节点的配置方式：（数据的存储和相关具体操作）
* node.master: false
* node.data: true

候选主节点的配置方式：（主节点负责创建索引、删除索引、分配分片、追踪集群中的节点状态等）
* node.master: true
* node.data: false

客户端节点的配置方式:（只负责请求的分发、汇总，实现节点间的协调和负载均衡）
* node.master: false
* node.data: false

考虑到实际情况和资源的合理利用，也可以既是 主节点，又是 数据节点

## 二、硬件配置

ES的内存配置不是越大越好，建议不能超过32GB，同时预留一半内存给Lucence使用。建议把50%的内存给ElasticSearch作为堆内存，剩下的50%留给Lucence。

建议单台服务器单节点的部署方式，如果单台服务器的内存大于64GB，比如是128GB内存的服务器，可以创建两个节点，每个节点使用不超过32GB的内存。即最多64GB内存给ES的堆内存，剩下的一半留给Lucence。同时，需要增加如下的配置项，避免同一个分片（shard）的主副本存在同一个物理服务器上，而无法使用到副本高可用性。
* cluster.routing.allocation.same_shard.host: true

## 三、ES 安装部署

测试环境说明：

| 序号 | 服务器IP            | 节点名称   | 内存容量 | 角色             |
|----|------------------|--------|------|----------------|
| 1  | 53\.36\.122\.142 | node01 | 64G  | master \+ data |
| 2  | 53\.36\.122\.143 | node02 | 64G  | master \+ data |
| 3  | 53\.36\.122\.144 | node03 | 64G  | master \+ data |
| 4  | 53\.36\.122\.145 | node04 | 64G  | data           |

### 3.1 安装环境准备

* 因 ES 自带了 open-jdk，使用自带的 jdk ，故不另外安装jdk环境
* 因 ES 不支持通过 **root** 用户运行，增加 **elasticsearch** 这个系统用户和 **elasticsearch** 组
* 修改系统配置 **/etc/security/limits.conf** ，增加系统针对特定用户的限制值
* 修改系统配置 **/etc/sysctl.conf** ，增加 **vm.max_map_count=655360** 的配置项
* 以下的说明以安装 elasticsearch-7.5.1 为例

相应的修改整理成 shell 脚本如下：

```sh
#!/bin/sh

ulimit -n 65535

echo "* soft nofile 65535" >> /etc/security/limits.conf
echo "* hard nofile 131072" >> /etc/security/limits.conf

echo "* soft nproc 4096" >> /etc/security/limits.conf
echo "* hard nproc 4096" >> /etc/security/limits.conf

echo "elasticsearch soft memlock unlimited" >> /etc/security/limits.conf
echo "elasticsearch hard memlock unlimited" >> /etc/security/limits.conf

sysctl -w vm.max_map_count=655360
echo "vm.max_map_count=655360" >> /etc/sysctl.conf

sysctl -p

groupadd elasticsearch
useradd elasticsearch -g elasticsearch
chown -R elasticsearch:elasticsearch /opt/app/elasticsearch-7.5.1
```

* 创建 ES 存储数据和日志的目录，本次安装数据存储目录为 /home/es_data/es/data，日志存储目录为 /home/es_data/es/logs，创建好相应的目录后，要修改目录拥有者

```sh
mkdir /home/es_data/es/data -p
mkdir /home/es_data/es/logs -p

chown -R elasticsearch:elasticsearch /home/es_data/es
```

### 3.2 修改 ES 的配置

```sh
#vi /opt/app/elasticsearch-7.5.1/config/elasticsearch.yml
```

node01 的配置如下：

```conf
# ----------------------- Cluster ------------------------------------
# 集群名称
cluster.name: es-cluster

# ----------------------- Node --------------------------------------
# 集群节点名称
node.name: node01

# ----------------------- Path ---------------------------------------
# data存储路径
path.data: /home/es_data/es/data
# 日志存储路径
path.logs: /home/es_data/es/logs

# ----------------------- Memory -------------------------------------
# 允许 JVM 锁住内存，禁止OS将es进程swapping出去，使进程更稳定，官方建议生产环境为true
bootstrap.memory_lock: true

# ----------------------- Network -----------------------------------
# 监听网卡地址
network.host: 53.36.122.142
# 监听端口
http.port: 9200

# ------------------------- Discovery --------------------------------
# 候选主节点的设备地址，在开启服务后可以被选为主节点
discovery.seed_hosts: ["53.36.122.142","53.36.122.143","53.36.122.144"]
# 初始集群master节点地址
cluster.initial_master_nodes: ["node01","node02","node03"]
# 此节点是否存数据
node.data: true
# 此节点是否可以竞选master
node.master: true

# ------------------------- Gateway -----------------------------------
# 在完全集群重启后阻止初始恢复，直到启动N个节点
gateway.recover_after_nodes: 3

# ---------------------------------- Various -----------------------------------
# 是否允许跨域访问，涉及elasticsearch-head等工具的访问
http.cors.enabled: true
http.cors.allow-origin: "*"
```

```sh
#vi /opt/app/elasticsearch-7.5.1/config/jvm.options
```

内存参数修改如下：

```conf
-Xms32g
-Xmx32g
```

### 3.3 拷贝 ES 到其他节点

```sh
scp -r /opt/app/elasticsearch-7.5.1 53.36.122.143@root:/opt/app
scp -r /opt/app/elasticsearch-7.5.1 53.36.122.144@root:/opt/app
scp -r /opt/app/elasticsearch-7.5.1 53.36.122.145@root:/opt/app
```

### 3.4 修改剩下3个节点的配置

* 剩下3个节点按 **3.1** 的说明执行，准备环境
* 按 **3.2** 的说明，修改配置，但 /opt/app/elasticsearch-7.5.1/config/elasticsearch.yml 中的 node.name 分别是 node02、node03、node04， network.host 按实际主机的 IP 地址来修改

node02 配置

```conf
# ----------------------- Cluster ------------------------------------
# 集群名称
cluster.name: es-cluster

# ----------------------- Node --------------------------------------
# 集群节点名称
node.name: node02

# ----------------------- Path ---------------------------------------
# data存储路径
path.data: /home/es_data/es/data
# 日志存储路径
path.logs: /home/es_data/es/logs

# ----------------------- Memory -------------------------------------
# 允许 JVM 锁住内存，禁止OS将es进程swapping出去，使进程更稳定，官方建议生产环境为true
bootstrap.memory_lock: true

# ----------------------- Network -----------------------------------
# 监听网卡地址
network.host: 53.36.122.143
# 监听端口
http.port: 9200

# ------------------------- Discovery --------------------------------
# 候选主节点的设备地址，在开启服务后可以被选为主节点
discovery.seed_hosts: ["53.36.122.142","53.36.122.143","53.36.122.144"]
# 初始集群master节点地址
cluster.initial_master_nodes: ["node01","node02","node03"]
# 此节点是否存数据
node.data: true
# 此节点是否可以竞选master
node.master: true

# ------------------------- Gateway -----------------------------------
# 在完全集群重启后阻止初始恢复，直到启动N个节点
gateway.recover_after_nodes: 3

# ---------------------------------- Various -----------------------------------
# 是否允许跨域访问，涉及elasticsearch-head等工具的访问
http.cors.enabled: true
http.cors.allow-origin: "*"
```

node03 配置

```conf
# ----------------------- Cluster ------------------------------------
# 集群名称
cluster.name: es-cluster

# ----------------------- Node --------------------------------------
# 集群节点名称
node.name: node03

# ----------------------- Path ---------------------------------------
# data存储路径
path.data: /home/es_data/es/data
# 日志存储路径
path.logs: /home/es_data/es/logs

# ----------------------- Memory -------------------------------------
# 允许 JVM 锁住内存，禁止OS将es进程swapping出去，使进程更稳定，官方建议生产环境为true
bootstrap.memory_lock: true

# ----------------------- Network -----------------------------------
# 监听网卡地址
network.host: 53.36.122.144
# 监听端口
http.port: 9200

# ------------------------- Discovery --------------------------------
# 候选主节点的设备地址，在开启服务后可以被选为主节点
discovery.seed_hosts: ["53.36.122.142","53.36.122.143","53.36.122.144"]
# 初始集群master节点地址
cluster.initial_master_nodes: ["node01","node02","node03"]
# 此节点是否存数据
node.data: true
# 此节点是否可以竞选master
node.master: true

# ------------------------- Gateway -----------------------------------
# 在完全集群重启后阻止初始恢复，直到启动N个节点
gateway.recover_after_nodes: 3

# ---------------------------------- Various -----------------------------------
# 是否允许跨域访问，涉及elasticsearch-head等工具的访问
http.cors.enabled: true
http.cors.allow-origin: "*"
```

node04 配置

```conf
# ----------------------- Cluster ------------------------------------
# 集群名称
cluster.name: es-cluster

# ----------------------- Node --------------------------------------
# 集群节点名称
node.name: node04

# ----------------------- Path ---------------------------------------
# data存储路径
path.data: /home/es_data/es/data
# 日志存储路径
path.logs: /home/es_data/es/logs

# ----------------------- Memory -------------------------------------
# 允许 JVM 锁住内存，禁止OS将es进程swapping出去，使进程更稳定，官方建议生产环境为true
bootstrap.memory_lock: true

# ----------------------- Network -----------------------------------
# 监听网卡地址
network.host: 53.36.122.145
# 监听端口
http.port: 9200

# ------------------------- Discovery --------------------------------
# 候选主节点的设备地址，在开启服务后可以被选为主节点
discovery.seed_hosts: ["53.36.122.142","53.36.122.143","53.36.122.144"]
# 初始集群master节点地址
cluster.initial_master_nodes: ["node01","node02","node03"]
# 此节点是否存数据
node.data: true
# 此节点是否可以竞选master
node.master: false

# ------------------------- Gateway -----------------------------------
# 在完全集群重启后阻止初始恢复，直到启动N个节点
gateway.recover_after_nodes: 3

# ---------------------------------- Various -----------------------------------
# 是否允许跨域访问，涉及elasticsearch-head等工具的访问
http.cors.enabled: true
http.cors.allow-origin: "*"
```

### 3.5 开机启动服务

创建脚本 /etc/init.d/elasticsearch，内容如下（脚本中的 **JAVA_HOME** 和 **JAVA_BIN** 根据实际部署时的路径调整）：

```sh
#!/bin/sh
#chkconfig: 2345 80 05
#description: elasticsearch
 
export JAVA_HOME=/opt/app/elasticsearch-7.5.1/jdk
export JAVA_BIN=/opt/app/elasticsearch-7.5.1/jdk/bin
export PATH=$PATH:$JAVA_HOME/bin
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
export JAVA_HOME JAVA_BIN PATH CLASSPATH

case "$1" in
start)
    su - elasticsearch<<!
    cd /opt/app/elasticsearch-7.5.1
    ./bin/elasticsearch -d
!
    echo "elasticsearch startup"
    ;;
stop)
    es_pid=`ps aux|grep elasticsearch | grep -v 'grep' | awk '{print $2}'`
    kill -9 $es_pid
    echo "elasticsearch stopped"
    ;;
restart)
    es_pid=`ps aux|grep elasticsearch | grep -v 'grep' | awk '{print $2}'`
    kill -9 $es_pid
    echo "elasticsearch stopped"
    su - elasticsearch<<!
    cd /opt/app/elasticsearch-7.5.1/
    ./bin/elasticsearch -d
!
    echo "elasticsearch startup"
    ;;
*)
    echo "start|stop|restart"
    ;;
esac

exit $?
```

* 为脚本增加执行权限: ```chmod +x /etc/init.d/elasticsearch```
* 配置开机启动 elasticsearch
```
cd /etc/init.d
chkconfig --add elasticsearch
```
* 重启后，通过 jps 查看进程是否有 elasticsearch 服务
* ```chkconfig --list``` 可查看开机启动服务列表

## 四、ES 监测工具安装

以安装 [cerebro](https://github.com/lmenezes/cerebro) 插件为例

* 下载 cerebro 的安装包
* 将 cerebro 安装包上传到服务器
* 执行命令解压安装包：tar zxvf cerebro-0.9.2.tgz
* 进行解压后的目录 cerebro下，并执行命令启动程序：./bin/cerebro
* 因cerebro默认监听9000端口，在浏览器中输入: http://ip:9000 即可进入 cerebro 管理页面
* 在页面中输入 ES 集群的访问地址，即可进入集群，并查看集群的状态

## 参考
1. [ElasticSearch优化系列一：集群节点规划](https://blog.csdn.net/leadai/article/details/78475422)
2. [ElasticSearch优化系列二：机器设置（内存）](https://blog.csdn.net/leadai/article/details/78475365?utm_source=blogxgwz3)
3. [elasticsearch6.0.1单机多节点集群搭建](https://blog.csdn.net/tyrroo/article/details/85775898)
4. [ElasticSearch 安装及开机启动](https://www.jianshu.com/p/ec32afeae868)
5. [Elasticsearch 在CentOs7 环境中开机启动](https://www.cnblogs.com/Rawls/p/10937280.html)
6. [Important discovery and cluster formation settings](https://www.elastic.co/guide/en/elasticsearch/reference/7.5/discovery-settings.html)

