---
title: 记一次Oracle数据库连接异常
date: 2020-04-08 10:43:00
category: Oracle
tags: Oracle, archivelog
layout: post
---

* 环境：Oracle RAC 11g
* 节点名称：rac01 和 rac02

## 一、故障描述

1. 数据库连接异常

通过 Navicat 连接 Oracle 数据库时，报错 "Connect internal only, until freed"， 网上查了一下，说了归档日志满了。但sqlplus登录到数据库，执行以下命令查询 flash recovery area 的使用情况

```sql
select * from V$FLASH_RECOVERY_AREA_USAGE;

FILE_TYPE PERCENT_SPACE_USED PERCENT_SPACE_RECLAIMABLE NUMBER_OF_FILES

CONTROLFILE .1 0 1
ONLINELOG 0 0 0
ARCHIVELOG 0 0 0
BACKUPPIECE 0 0 0
IMAGECOPY 0 0 0
FLASHBACKLOG 30.45 30.13 189
```

从上面的提示信息来看，flash recovery area 区域并没有满。

2. 数据库归档异常

检查后，打算把期间一个处于 open 状态的实例关闭，但一直无法关闭，查看数据库日志

首先通过下面的 sql 找到数据库日志的路径

```sql
show parameter backg

NAME TYPE VALUE
backgroud_core_dump string partial
backgroud_dump_dest string /home/u01/product/oracle/diag/rdbms/orcl/orcl1/trace/
```

再用下面的 sh 命令查看数据库日志最后100行的信息

```sh
tail -100 /home/u01/product/oracle/diag/rdbms/orcl/orcl1/trace/alert_orcl1.log
```

发现数据库无法关闭，提示如下的信息

```sh
ORA-16038: log 3 sequence# 6 cannot be archived
```

## 二、故障排查和处理

1. 查询 recovery 目录

```sql
show parameter recover;

NAME TYPE VALUE
db_recovery_file_dest string +ASM_DATA
db_recovery_file_dest_size big integer 20G
recovery_parallelism integer 0
```

2. 查看archivelog目录的存储文件情况

切换到 grid 用户，并通过 asmcmd 登录到 asm 命令行模块，并切换到 archivelog 目录下，并通过 ls 命令查看该目录下文件的情况

```
cd +ASM_DATA/ORCL/ARCHIVELOG
ls
```

3. 删除旧的归档文件

* 尝试方式一

根据故障信息的第2点描述，尝试使用以下的 sql 来清除需要归档的信息， **但执行失败**

```sql
alter database clear unarchived logfile group 3;
```

* 尝试方式二：通过rman来清除旧的归档文件

切换到 oracle 用户，并登录到rman中，执行以下的命令

```sql
[oracle@osc ~]$ rman target /

Recovery Manager: Release 11.2.0.1.0 - Production on Mon Nov 12 17:48:41 2018

Copyright (c) 1982, 2011, Oracle and/or its affiliates.  All rights reserved.

connected to target database: ORCL (DBID=1511487649)
RMAN> crosscheck archivelog all; 
RMAN> delete archivelog until time 'sysdate-7';
RMAN> delete expired archivelog all;
```

* crosscheck archivelog all: 验证的是DB的归档日志即log_archive_dest参数指定位置的文件

当手工删除了归档日志以后，Rman备份会检测到日志缺失，从而无法进一步继续执行。所以此时需要手工执行crosscheck过程，之后Rman备份可以恢复正常。 **无法进入rman的时候，可以直接删除归档日志文件，然后再执行这条语句！**

* delete archivelog until time 'sysdate-7': 删除当前时间-7天前的归档日志

* delete expired archivelog all：删除过期或无效的归档日志， **建议：在删除归档日志后做一次物理备份**

删除完成后，数据库恢复正常，但在 asm 中查看数据，相应的dbf文件还在，但执行rm指定的一个旧归档文件时，会提示文件不存在。第二天再过来的时候，可以正常执行rm删除指定旧的归档文件。但 **flash recovery area的空间大小一直没变化（该问题，后续再详细检查）**

## 三、数据库状态

用户使用 sqlplus 登录数据库后，可使用以下的命令来查看数据库当前的服务状态

```sql
SQL> select status from v$instance;
```

| 数据库状态    | 说明                                |
|----------|-----------------------------------|
| shutdown | 数据库未启动                            |
| nomount  | SGA和后台进程已启动                       |
| mount    | sysdba权限的用户可以进行数据备份和恢复操作，普通用户不能访问 |
| open     | 所有用户可正常访问                         |

* shutdonw --> nomount

执行以下sql，要从 shutdown 状态 到 nomount 状态；首先从spfile或pfile中读取数据库参数文件，然后分配SGA和创建后台进程。

```sql
SQL> startup nomount;
```

* nomount --> mount

根据初始化参数文件中的 CONTROL_FILE 参数找到相应的控制文件然后打开它们。在控制文件中包含了数据库的数据文件和 redo log 文件信息；只有数据库管理员可以进行一些备份恢复等工作。

```sql
SQL> alter database mount;
```

* mount --> open

数据库对外开始提供服务

```sql
SQL> alter database open;
```

* 立即关闭数据库（无损关闭）

```sql
SQL> shutdown immediate;
```

* 终止关闭数据库（有脏数据的关闭）

```sql
SQL> shutdown abort;
```

## 四、归档状态及设置

* 查看归档方式

```sql
SQL> archive log list;
```

以下命令，需要数据库在 mount 状态下执行，数据再启动后才生效，如果是RAC模式，需要把多个实例先切换到 mount 状态。

* 关闭闪回数据库模式

```sql
alter database flashback off;
```

* 将数据库改为非归档模式

```sql
alter database noarchivelog;
```

* 调整归档空间大小

```sql
SQL> alter system set db_recovery_file_dest_size=3G scope=both;
```

## 参考
1. [浅谈Oracle归档日志](https://www.jianshu.com/p/4d8dd25267d9)
2. [查看Oracle数据库实例启动状态](https://blog.csdn.net/xiezuoyong/article/details/81327756)

