---
title: Centos 7.4部署CDH说明
date: 2019-08-07 11:18:55
category: hadoop
tags: hadoop, CDH
layout: post

---

## 一、前期准备

### 1.1 系统安装

* 4台已经安装好Centos 7.4操作系统的机器
* 下载好相应的离线安装包

### 1.2 系统配置

#### 1.2.1 所有节点禁用SELinux

* 临时禁用SELinux

```sh
[root@localhost ~]# setenforce 0
```

* 永久禁用SELinux

修改/etc/selinux/config文件如下：

```sh
SELINUX=disabled
SELINUXTYPE=targeted
```

#### 1.2.2 所有节点关闭防火墙

```sh
[root@localhost yum.repos.d]# systemctl stop firewalld
[root@localhost yum.repos.d]# systemctl disable firewalld
Removed symlink /etc/systemd/system/multi-user.target.wants/firewalld.service.
Removed symlink /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service.
[root@localhost yum.repos.d]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
Active: inactive (dead)
Docs: man:firewalld(1)

May 07 17:16:20 localhost.localdomain systemd[1]: Starting firewalld - dynamic firewall daemon...
May 07 17:16:21 localhost.localdomain systemd[1]: Started firewalld - dynamic firewall daemon.
May 08 09:57:15 localhost.localdomain systemd[1]: Stopping firewalld - dynamic firewall daemon...
May 08 09:57:16 localhost.localdomain systemd[1]: Stopped firewalld - dynamic firewall daemon.
```

#### 1.2.3 设置hostname及hosts配置

以cm节点44.54.11.38为例，集群其他节点参照修改

* hostname配置

修改/etc/hostname文件如下：

```sh
hadoop-44-54-11-38
```

或通过命令修改立即生效

```sh
[root@ip-172-31-2-159 home]# hostnamectl set-hostname hadoop-44-54-11-38
```

* hosts修改文件如下

```sh
127.0.0.1 localhost localhost.localdomain localhost4 localhost4.localdomain4
::1 localhost localhost.localdomain localhost6 localhost6.localdomain6

44.54.11.38 hadoop-44-54-11-38
44.54.11.39 hadoop-44-54-11-39
44.54.11.40 hadoop-44-54-11-40
44.54.11.41 hadoop-44-54-11-41
```

## 二、Yum源配置

### 2.1 Yum源服务器配置

注意： **以下操作只在一个节点上执行，在本地搭建Yum源**

#### 2.1.1 系统ISO挂载

DVD-ROM挂载方式和ISO文件挂载方式二选一

##### 2.1.1.1 DVD-ROM挂载方式

此处省略，后续补充

##### 2.1.1.2 ISO文件挂载方式

* 通过SCP或SSH工具将操作系统的ISO文件上传到指定目录（以/home目录为例），上传完成后，查看/home目录

```sh
[root@ip-172-31-2-159 home]# ls
centos7-iso CentOS-7-x86_64-DVD-1810.iso disk1 lost+found nginx-1.14.2-1.el6.ngx.x86_64.rpm
```

* 将ISO文件挂载到本地目录下（以/media/cdrom为例）

```sh
[root@ip-172-31-2-159 home]# mount -o loop /home/CentOS-7-x86_64-DVD-1810.iso /media/cdrom
```

#### 2.1.2 Yum源文件拷贝

* 创建一个目录，并将ISO中的所有文件拷贝到该目录下(以/home/centos7-iso目录为例)

```sh
[root@ip-172-31-2-159 home]# mkdir centos7-iso
[root@ip-172-31-2-159 home]# scp -r /media/cdrom/* /home/centos7-iso
[root@ip-172-31-2-159 home]# cd centos7-iso
[root@ip-172-31-2-159 centos7-iso]# ls
CentOS_BuildTag EFI EULA GPL images index.html isolinux LiveOS Packages repodata RPM-GPG-KEY-CentOS-7 RPM-GPG-KEY-CentOS-Testing-7 TRANS.TBL
```

#### 2.1.3 创建基于HTTP的Yum源

* 安装HTTP服务（以安装nginx为例）
* 下载nginx的rpm安装包，并上传和执行安装
* 通过软连接将ISO文件挂载到nginx的HTTP服务目录下

```sh
[root@ip-172-31-2-159 home]# rpm -ihv nginx-1.14.2-1.el7.ngx.x86_64.rpm
[root@ip-172-31-2-159 home]# cd /usr/share/nginx/html
[root@ip-172-31-2-159 html]# ln -s /home/centos7-iso /usr/share/nginx/html/iso
```

### 2.2 集群服务器Yum源配置

* 增加新的repo文件

```sh
[root@ip-172-31-2-159 ~]# vi /etc/yum.repos.d/os.repo
[osrepo]
name=os_repo
baseurl=http://44.54.11.38/iso/
enabled=true
gpgcheck=false
[root@ip-172-31-2-159 ~]# yum repolist
```

## 三、系统其他配置

### 3.1 集群时钟同步

* 集群所有机器卸载chrony

```sh
[root@hadoop-44-54-11-38 ~]# yum -y remove chrony
Loaded plugins: fastestmirror, langpacks
Resolving Dependencies
--> Running transaction check
---> Package chrony.x86_64 0:3.2-2.el7 will be erased
--> Finished Dependency Resolution
Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=os&infra=stock error was
14: curl#6 - "Could not resolve host: mirrorlist.centos.org; Unknown error"
Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=extras&infra=stock error was
14: curl#6 - "Could not resolve host: mirrorlist.centos.org; Unknown error"
osrepo | 3.6 kB 00:00:00
osrepo/group_gz | 166 kB 00:00:00
osrepo/primary_db | 3.1 MB 00:00:00
Could not retrieve mirrorlist http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=updates&infra=stock error was
14: curl#6 - "Could not resolve host: mirrorlist.centos.org; Unknown error"

Dependencies Resolved

==============================================================================================================================================================================================================================================================================
Package Arch Version Repository Size
==============================================================================================================================================================================================================================================================================
Removing:
chrony x86_64 3.2-2.el7 @anaconda 476 k

Transaction Summary
==============================================================================================================================================================================================================================================================================
Remove 1 Package

Installed size: 476 k
Downloading packages:
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
Erasing : chrony-3.2-2.el7.x86_64 1/1
Verifying : chrony-3.2-2.el7.x86_64 1/1

Removed:
chrony.x86_64 0:3.2-2.el7

Complete!
```

* 集群所有机器安装ntpd

```sh
[root@hadoop-44-54-11-41 ~]# yum -y install ntp
```

* 修改ntpd的配置

```sh
[root@hadoop-44-54-11-41 ~]# vi /etc/ntp.conf

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
server 16.81.240.188
```

修改后的完整配置文件如下：

```conf
# For more information about this file, see the man pages
# ntp.conf(5), ntp_acc(5), ntp_auth(5), ntp_clock(5), ntp_misc(5), ntp_mon(5).

driftfile /var/lib/ntp/drift

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict default nomodify notrap nopeer noquery

# Permit all access over the loopback interface. This could
# be tightened as well, but to do so would effect some of
# the administrative functions.
restrict 127.0.0.1
restrict ::1

# Hosts on local network are less restricted.
#restrict 192.168.1.0 mask 255.255.255.0 nomodify notrap

# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
#server 0.centos.pool.ntp.org iburst
#server 1.centos.pool.ntp.org iburst
#server 2.centos.pool.ntp.org iburst
#server 3.centos.pool.ntp.org iburst
server 16.81.240.188

#broadcast 192.168.1.255 autokey # broadcast server
#broadcastclient # broadcast client
#broadcast 224.0.1.1 autokey # multicast server
#multicastclient 224.0.1.1 # multicast client
#manycastserver 239.255.254.254 # manycast server
#manycastclient 239.255.254.254 autokey # manycast client

# Enable public key cryptography.
#crypto

includefile /etc/ntp/crypto/pw

# Key file containing the keys and key identifiers used when operating
# with symmetric key cryptography.
keys /etc/ntp/keys

# Specify the key identifiers which are trusted.
#trustedkey 4 8 42

# Specify the key identifier to use with the ntpdc utility.
#requestkey 8

# Specify the key identifier to use with the ntpq utility.
#controlkey 8

# Enable writing of statistics records.
#statistics clockstats cryptostats loopstats peerstats

# Disable the monitoring facility to prevent amplification attacks using ntpdc
# monlist command when default restrict does not include the noquery flag. See
# CVE-2013-5211 for more details.
# Note: Monitoring will not be disabled with the limited restriction flag.
disable monitor
```

* 启动ntpd服务

```sh
[root@hadoop-44-54-11-41 ~]# systemctl restart ntpd
[root@hadoop-44-54-11-41 ~]# systemctl status ntpd
● ntpd.service - Network Time Service
Loaded: loaded (/usr/lib/systemd/system/ntpd.service; disabled; vendor preset: disabled)
Active: active (running) since Wed 2019-05-08 15:50:48 CST; 4s ago
Process: 54487 ExecStart=/usr/sbin/ntpd -u ntp:ntp $OPTIONS (code=exited, status=0/SUCCESS)
Main PID: 54488 (ntpd)
CGroup: /system.slice/ntpd.service
└─54488 /usr/sbin/ntpd -u ntp:ntp -g

May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: Listen and drop on 0 v4wildcard 0.0.0.0 UDP 123
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: Listen and drop on 1 v6wildcard :: UDP 123
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: Listen normally on 2 lo 127.0.0.1 UDP 123
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: Listen normally on 3 eth0 44.54.11.41 UDP 123
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: Listen normally on 4 lo ::1 UDP 123
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: Listen normally on 5 eth0 fe80::66e6:8c50:d3ae:91c3 UDP 123
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: Listening on routing socket on fd #22 for interface updates
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: 0.0.0.0 c016 06 restart
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: 0.0.0.0 c012 02 freq_set kernel 0.000 PPM
May 08 15:50:48 hadoop-44-54-11-41 ntpd[54488]: 0.0.0.0 c011 01 freq_not_set
[root@hadoop-44-54-11-41 ~]# systemctl enable ntpd
Created symlink from /etc/systemd/system/multi-user.target.wants/ntpd.service to /usr/lib/systemd/system/ntpd.service.
```

### 3.2 设置SWAP

```sh
[root@hadoop-44-54-11-38 etc]# echo vm.swappiness = 1 >> /etc/sysctl.conf
[root@hadoop-44-54-11-38 etc]# sysctl vm.swappiness=1
```

### 3.3 设置透明大页面

* 当前设置生效，在集群所有节点执行

```sh
[root@hadoop-44-54-11-38 etc]# echo never > /sys/kernel/mm/transparent_hugepage/defrag
[root@hadoop-44-54-11-38 etc]# echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

* 设置开机自关闭，在集群所有节点修改

在/etc/rc.d/rc.local文件中添加以下内容

```sh
if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
echo never > /sys/kernel/mm/transparent_hugepage/enabled
fi

if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi
```

修改/etc/rc.d/rc.local的权限

```sh
[root@hadoop-44-54-11-38 etc]# chmod +x /etc/rc.d/rc.local
```

## 四、安装CDH

### 4.1 安装MariaDB

* 安装MariaDB

```sh
[root@hadoop-44-54-11-40 etc]# yum -y install mariadb
[root@hadoop-44-54-11-40 etc]# yum -y install mariadb-server
```

* 如果mariadb服务在运行，则先停止服务

```sh
[root@hadoop-44-54-11-38 ~]# ystemctl stop mariadb
```

* 修改/etc/my.cnf

参照[Cloudera官方网站的推荐配置](<https://www.cloudera.com/documentation/enterprise/6/latest/topics/install_cm_mariadb.html#install_cm_mariadb>)修改

```conf
[mysqld]
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock
transaction-isolation = READ-COMMITTED
# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
# Settings user and group are ignored when systemd is used.
# If you need to run mysqld under a different user or group,
# customize your systemd unit file for mariadb according to the
# instructions in http://fedoraproject.org/wiki/Systemd

key_buffer = 16M
key_buffer_size = 32M
max_allowed_packet = 32M
thread_stack = 256K
thread_cache_size = 64
query_cache_limit = 8M
query_cache_size = 64M
query_cache_type = 1

max_connections = 550
#expire_logs_days = 10
#max_binlog_size = 100M

#log_bin should be on a disk with enough free space.
#Replace '/var/lib/mysql/mysql_binary_log' with an appropriate path for your
#system and chown the specified folder to the mysql user.
log_bin=/var/lib/mysql/mysql_binary_log

#In later versions of MariaDB, if you enable the binary log and do not set
#a server_id, MariaDB will not start. The server_id must be unique within
#the replicating group.
server_id=1

binlog_format = mixed

read_buffer_size = 2M
read_rnd_buffer_size = 16M
sort_buffer_size = 8M
join_buffer_size = 8M

# InnoDB settings
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 64M
innodb_buffer_pool_size = 4G
innodb_thread_concurrency = 8
innodb_flush_method = O_DIRECT
innodb_log_file_size = 512M

[mysqld_safe]
log-error=/var/log/mariadb/mariadb.log
pid-file=/var/run/mariadb/mariadb.pid

#
# include all files from the config directory
#
!includedir /etc/my.cnf.d
```

* 配置开机启动并启动和配置MariaDB

```sh
[root@hadoop-44-54-11-38 ~]# systemctl enable mariadb
[root@hadoop-44-54-11-38 ~]# systemctl start mariadb
[root@hadoop-44-54-11-38 ~]# /usr/bin/mysql_secure_installation
```

```sh
NOTE: RUNNING ALL PARTS OF THIS SCRIPT IS RECOMMENDED FOR ALL MariaDB
SERVERS IN PRODUCTION USE! PLEASE READ EACH STEP CAREFULLY!

In order to log into MariaDB to secure it, we'll need the current
password for the root user. If you've just installed MariaDB, and
you haven't set the root password yet, the password will be blank,
so you should just press enter here.

Enter current password for root (enter for none):
OK, successfully used password, moving on...

Setting the root password ensures that nobody can log into the MariaDB
root user without the proper authorisation.

Set root password? [Y/n] Y
New password:
Re-enter new password:
Password updated successfully!
Reloading privilege tables..
... Success!


By default, a MariaDB installation has an anonymous user, allowing anyone
to log into MariaDB without having to have a user account created for
them. This is intended only for testing, and to make the installation
go a bit smoother. You should remove them before moving into a
production environment.

Remove anonymous users? [Y/n] Y
... Success!

Normally, root should only be allowed to connect from 'localhost'. This
ensures that someone cannot guess at the root password from the network.

Disallow root login remotely? [Y/n] n
... skipping.

By default, MariaDB comes with a database named 'test' that anyone can
access. This is also intended only for testing, and should be removed
before moving into a production environment.

Remove test database and access to it? [Y/n] Y
- Dropping test database...
... Success!
- Removing privileges on test database...
... Success!

Reloading the privilege tables will ensure that all changes made so far
will take effect immediately.

Reload privilege tables now? [Y/n] Y
... Success!

Cleaning up...

All done! If you've completed all of the above steps, your MariaDB
installation should now be secure.

Thanks for using MariaDB!
```

### 4.2 创建CM及相关组件的数据库

其中password为需要设置的密码，这里设置为hadoop

```sql
create database scm default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'scm'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON scm. * TO 'scm'@'%';
FLUSH PRIVILEGES;

create database amon default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'amon'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON amon. * TO 'amon'@'%';
FLUSH PRIVILEGES;

create database rman default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'rman'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON rman. * TO 'rman'@'%';
FLUSH PRIVILEGES;

create database hue default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'hue'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON hue. * TO 'hue'@'%';
FLUSH PRIVILEGES;

create database metastore default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'hive'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON metastore. * TO 'hive'@'%';
FLUSH PRIVILEGES;

create database sentry default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'sentry'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON sentry. * TO 'sentry'@'%';
FLUSH PRIVILEGES;

create database nav default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'nav'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON nav. * TO 'nav'@'%';
FLUSH PRIVILEGES;

create database navms default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'navms'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON navms. * TO 'navms'@'%';
FLUSH PRIVILEGES;

create database oozie default character set utf8 DEFAULT COLLATE utf8_general_ci;;
CREATE USER 'oozie'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON oozie. * TO 'oozie'@'%';
FLUSH PRIVILEGES;
```

```sh
MariaDB [(none)]> create database scm default character set utf8; CREATE USER 'scm'@'%' IDENTIFIED BY 'hadoop'; GRANT ALL PRIVILEGES ON scm. * TO 'scm'@'%'; FLUSH PRIVILEGES;
RANT ALL PRIVILEGES ON amon. * TO 'amon'@'%';
FLUSH PRIVILEGES;

create database rman default character set utf8;
CREATE USER 'rman'@'%' IDENTIFIED BY 'hadoop';
GRANT ALL PRIVILEGES ON rman. * TO 'rman'@'%';
FLUSH PRIVILEGES;

create database hue default cQuery OK, 1 row affected (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database amon default character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> CREATE USER 'amon'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON amon. * TO 'amon'@'%';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database rman default character set utf8;
haracter set utf8;
CREATE USER 'hue'@'%' IDENTIFIED BY 'hadoop';
GRANT ALL PRIVILEGES ON hue. * TO 'hue'@'%';
FLUSH PRIVILEGES;

create database metastore default character set utf8;
CREATE USER 'hive'@'%' IDENTIFIED BY 'hadoop';
GRANT ALL PRIVILEGEQuery OK, 1 row affected (0.00 sec)S
ON me
MariaDB [(none)]> CREATE USER 'rman'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON rman. * TO 'rman'@'%';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database hue default character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> CREATE USER 'hue'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON hue. * TO 'hue'@'%';
Query OK, 0 rows affected (0.01 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database metastore default character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> CREATE USER 'hive'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON metastore. * TO 'hive'@'%';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database sentry default character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> CREATE USER 'sentry'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON sentry. * TO 'sentry'@'%';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database nav default character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> CREATE USER 'nav'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nav. * TO 'nav'@'%';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database navms default character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> CREATE USER 'navms'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON navms. * TO 'navms'@'%';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]>
MariaDB [(none)]> create database oozie default character set utf8;
Query OK, 1 row affected (0.00 sec)

MariaDB [(none)]> CREATE USER 'oozie'@'%' IDENTIFIED BY 'hadoop';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON oozie. * TO 'oozie'@'%';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database |
+--------------------+
| information_schema |
| amon |
| hue |
| metastore |
| mysql |
| nav |
| navms |
| oozie |
| performance_schema |
| rman |
| scm |
| sentry |
+--------------------+
12 rows in set (0.00 sec)

MariaDB [(none)]> SHOW GRANTS FOR hive
-> ;
+-----------------------------------------------------------------------------------------------------+
| Grants for hive@% |
+-----------------------------------------------------------------------------------------------------+
| GRANT USAGE ON *.* TO 'hive'@'%' IDENTIFIED BY PASSWORD '*B34D36DA2C3ADBCCB80926618B9507F5689964B6' |
| GRANT ALL PRIVILEGES ON `metastore`.* TO 'hive'@'%' |
+-----------------------------------------------------------------------------------------------------+
2 rows in set (0.00 sec)

MariaDB [(none)]>
```

### 4.3 下载CDH和Cloudera Manager安装包

* 下载 Cloudera Manager 安装包

```conf
https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm
https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm
https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm
https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/cloudera-manager-server-db-2-6.2.0-968826.el7.x86_64.rpm
https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/enterprise-debuginfo-6.2.0-968826.el7.x86_64.rpm
https://archive.cloudera.com/cm6/6.2.0/redhat7/yum/RPMS/x86_64/oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm
https://archive.cloudera.com/cm6/6.2.0/allkeys.asc
```

* 下载 CDH 安装包

```conf
https://archive.cloudera.com/cdh6/6.2.0/parcels/CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel
https://archive.cloudera.com/cdh6/6.2.0/parcels/CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha1
https://archive.cloudera.com/cdh6/6.2.0/parcels/CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha256
https://archive.cloudera.com/cdh6/6.2.0/parcels/manifest.json
```

### 4.4 创建Cloudera Manager的repo源

* 将Cloudera Manager安装需要的6个rpm包以及一个asc文件下载到本地，放在同一目录，执行createrepo命令生成rpm元数据

```sh
[root@hadoop-44-54-11-38 cdh6.2]# pwd
/home/cdh6.2
[root@hadoop-44-54-11-38 cdh6.2]# ll *6.2
cdh6.2:
total 2038784
-rw-r--r--. 1 root root 2087665645 May 8 13:41 CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel
-rw-r--r--. 1 root root 40 May 8 19:33 CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha1
-rw-r--r--. 1 root root 64 May 8 13:36 CDH-6.2.0-1.cdh6.2.0.p0.967373-el7.parcel.sha256
-rw-r--r--. 1 root root 33725 May 8 19:33 manifest.json

cm6.2:
total 1364104
-rw-r--r--. 1 root root 14041 May 8 19:32 allkeys.asc
-rw-r--r--. 1 root root 10215488 May 8 13:36 cloudera-manager-agent-6.2.0-968826.el7.x86_64.rpm
-rw-r--r--. 1 root root 1187380436 May 8 13:40 cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm
-rw-r--r--. 1 root root 9984 May 8 13:40 cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm
-rw-r--r--. 1 root root 10992 May 8 13:40 cloudera-manager-server-db-2-6.2.0-968826.el7.x86_64.rpm
-rw-r--r--. 1 root root 14200108 May 8 13:40 enterprise-debuginfo-6.2.0-968826.el7.x86_64.rpm
-rw-r--r--. 1 root root 184988341 May 8 13:40 oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm
[root@hadoop-44-54-11-38 cdh6.2]# cd cm6.2
[root@hadoop-44-54-11-38 cm6.2]# createrepo .
Spawning worker 0 with 6 pkgs
Workers Finished
Gathering worker results

Saving Primary metadata
Saving file lists metadata
Saving other metadata
Generating sqlite DBs
Sqlite DBs complete
[root@hadoop-44-54-11-38 cm6.2]# ln -s /home/cdh6.2/ /usr/share/nginx/html/cdh6.2
```

### 4.5 增加Cloudera Manager的Yum源

```sh
[root@hadoop-44-54-11-38 yum.repos.d]# vi cm.repo
[root@hadoop-44-54-11-38 yum.repos.d]# cat /etc/yum.repos.d/cm.repo
[cmrepo]
name=cm_repo
baseurl=http://44.54.11.38/cdh6.2/cm6.2
enabled=true
gpgcheck=false
[root@hadoop-44-54-11-38 yum.repos.d]# yum repolist
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
cmrepo | 2.9 kB 00:00:00
cmrepo/primary_db | 9.0 kB 00:00:00
repo id repo name status
cmrepo cm_repo 6
osrepo os_repo 4,021
repolist: 4,027
```

## 五、安装CDH和CM

### 5.1 安装JDK和Cloudera Manager

```sh
[root@hadoop-44-54-11-38 yum.repos.d]# yum -y install oracle-j2sdk1.8-1.8.0+update181-1.x86_64
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
Resolving Dependencies
--> Running transaction check
---> Package oracle-j2sdk1.8.x86_64 0:1.8.0+update181-1 will be installed
--> Finished Dependency Resolution

Dependencies Resolved

=====================================================================================================================================================================================
Package Arch Version Repository Size
====================================================================================================================================================================================
Installing:
oracle-j2sdk1.8 x86_64 1.8.0+update181-1 cmrepo 176 M

Transaction Summary
=====================================================================================================================================================================================
Install 1 Package
Total download size: 176 M
Installed size: 364 M
Downloading packages:
oracle-j2sdk1.8-1.8.0+update181-1.x86_64.rpm | 176 MB 00:00:02
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
Installing : oracle-j2sdk1.8-1.8.0+update181-1.x86_64 1/1
Verifying : oracle-j2sdk1.8-1.8.0+update181-1.x86_64 1/1

Installed:
oracle-j2sdk1.8.x86_64 0:1.8.0+update181-1
Complete!
[root@hadoop-44-54-11-38 yum.repos.d]# yum -y install cloudera-manager-server
Loaded plugins: fastestmirror, langpacks
Loading mirror speeds from cached hostfile
Resolving Dependencies
--> Running transaction check
---> Package cloudera-manager-server.x86_64 0:6.2.0-968826.el7 will be installed
--> Processing Dependency: cloudera-manager-daemons = 6.2.0 for package: cloudera-manager-server-6.2.0-968826.el7.x86_64
--> Running transaction check
---> Package cloudera-manager-daemons.x86_64 0:6.2.0-968826.el7 will be installed
--> Finished Dependency Resolution

Dependencies Resolved
=====================================================================================================================================================================================
Package Arch Version Repository Size
=====================================================================================================================================================================================
Installing:
cloudera-manager-server x86_64 6.2.0-968826.el7 cmrepo 9.8 k
Installing for dependencies:
cloudera-manager-daemons x86_64 6.2.0-968826.el7 cmrepo 1.1 G

Transaction Summary
=====================================================================================================================================================================================
Install 1 Package (+1 Dependent package)

Total download size: 1.1 G
Installed size: 1.3 G
Downloading packages:
(1/2): cloudera-manager-server-6.2.0-968826.el7.x86_64.rpm | 9.8 kB 00:00:00
(2/2): cloudera-manager-daemons-6.2.0-968826.el7.x86_64.rpm | 1.1 GB 00:00:24
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total 46 MB/s | 1.1 GB 00:00:24
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
Installing : cloudera-manager-daemons-6.2.0-968826.el7.x86_64 1/2
Installing : cloudera-manager-server-6.2.0-968826.el7.x86_64 2/2
Created symlink from /etc/systemd/system/multi-user.target.wants/cloudera-scm-server.service to /usr/lib/systemd/system/cloudera-scm-server.service.
Verifying : cloudera-manager-daemons-6.2.0-968826.el7.x86_64 1/2
Verifying : cloudera-manager-server-6.2.0-968826.el7.x86_64 2/2

Installed:
cloudera-manager-server.x86_64 0:6.2.0-968826.el7

Dependency Installed:
cloudera-manager-daemons.x86_64 0:6.2.0-968826.el7

Complete!
[root@hadoop-44-54-11-38 yum.repos.d]#
```

### 5.2 初始化数据库

* 安装JDB驱动

```sh
[root@hadoop-44-54-11-38 home]# wget https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.46.tar.gz
[root@hadoop-44-54-11-38 home]# tar zxvf mysql-connector-java-5.1.46.tar.gz
[root@hadoop-44-54-11-38 home]# mkdir -p /usr/share/java/
[root@hadoop-44-54-11-38 home]# cd mysql-connector-java-5.1.46
[root@hadoop-44-54-11-38 home]# cp mysql-connector-java-5.1.46-bin.jar /usr/share/java/mysql-connector-java.jar
[root@hadoop-44-54-11-38 home]# ln -s mysql-connector-java-5.1.34.jar mysql-connector-java.jar
```

* 初始化数据库

其中的password根据前面设置的密码输入

```sh
[root@hadoop-44-54-11-38 schema]# /opt/cloudera/cm/schema/scm_prepare_database.sh mysql scm scm password
JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
Verifying that we can write to /etc/cloudera-scm-server
Creating SCM configuration file in /etc/cloudera-scm-server
Executing: /usr/java/jdk1.8.0_181-cloudera/bin/java -cp /usr/share/java/mysql-connector-java.jar:/usr/share/java/oracle-connector-java.jar:/usr/share/java/postgresql-connector-java.jar:/opt/cloudera/cm/schema/../lib/* com.cloudera.enterprise.dbutil.DbCommandExecutor /etc/cloudera-scm-server/db.properties com.cloudera.cmf.db.
[ main] DbCommandExecutor INFO Successfully connected to database.
All done, your SCM database is configured correctly!
```

### 5.3 启动Cloudera Manager

```sh
[root@hadoop-44-54-11-38 schema]# systemctl start cloudera-scm-server
[root@hadoop-44-54-11-38 schema]# systemctl status cloudera-scm-server
● cloudera-scm-server.service - Cloudera CM Server Service
Loaded: loaded (/usr/lib/systemd/system/cloudera-scm-server.service; enabled; vendor preset: disabled)
Active: active (running) since Wed 2019-05-08 20:31:29 CST; 1min 30s ago
Main PID: 70376 (java)
CGroup: /system.slice/cloudera-scm-server.service
└─70376 /usr/java/jdk1.8.0_181-cloudera/bin/java -cp .:/usr/share/java/mysql-connector-java.jar:/usr/share/java/oracle-connector-java.jar:/usr/share/java/postgresql-connector-java.jar:lib/* -serv...

May 08 20:31:29 hadoop-44-54-11-38 systemd[1]: Started Cloudera CM Server Service.
May 08 20:31:29 hadoop-44-54-11-38 cm-server[70376]: JAVA_HOME=/usr/java/jdk1.8.0_181-cloudera
May 08 20:31:29 hadoop-44-54-11-38 cm-server[70376]: Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=256m; support was removed in 8.0
May 08 20:31:31 hadoop-44-54-11-38 cm-server[70376]: ERROR StatusLogger No log4j2 configuration file found. Using default configuration: logging only errors to the console. Set system property ...tion logging.
May 08 20:31:36 hadoop-44-54-11-38 cm-server[70376]: 20:31:36.819 [main] ERROR org.hibernate.engine.jdbc.spi.SqlExceptionHelper - Table 'scm.CM_VERSION' doesn't exist
Hint: Some lines were ellipsized, use -l to show in full.
[root@hadoop-44-54-11-38 schema]# netstat -lpnt | grep 7180
tcp 0 0 0.0.0.0:7180 0.0.0.0:* LISTEN 70376/java
```

### 5.4 配置cdh

* 通过浏览器访问 http://ip:7180 访问CM (ip为安装cm的机器的IP地址)

![CM登录页](<http://111.229.152.231/images/note/2019/cdh_install/cm-login.png>)

* 输入默认用户名和密码:admin/admin后，进入以下的欢迎页

![欢迎页](<http://111.229.152.231/images/note/2019/cdh_install/welcome-page.png>)

* 同意授权，并继续

![授权页](<http://111.229.152.231/images/note/2019/cdh_install/license.png>)

* 选择60天试，并继续

![版本选择页](<http://111.229.152.231/images/note/2019/cdh_install/version-pick.png>)

* 点击继续，进到集群配置的欢迎页

![集群配置欢迎页](<http://111.229.152.231/images/note/2019/cdh_install/continue.png>)

* 配置集群名称

![配置集群名称](<http://111.229.152.231/images/note/2019/cdh_install/cluster_name.png>)

* 输入主机名称或IP地址，点击搜索找到主机后点击继续

![主机搜索](<http://111.229.152.231/images/note/2019/cdh_install/specify_hosts.png>)

* 使用Parcel选择，点击“更多选项”，输入cdh的parcel文件路径，点击保存更改

![存储库配置](<http://111.229.152.231/images/note/2019/cdh_install/repository-select.png>)
![Parcel选择](<http://111.229.152.231/images/note/2019/cdh_install/parcel-setting.png>)

* 选择自定义存储库，输入cm的http地址并点击继续

![CM存储库选择](<http://111.229.152.231/images/note/2019/cdh_install/parcel-setting.png>)

* 安装jdk，并点击继续

![JDK安装](<http://111.229.152.231/images/note/2019/cdh_install/jdk-install.png>)

* 配置服务器主机的ssh用户名和密码，并点击继续

![SSH配置](<http://111.229.152.231/images/note/2019/cdh_install/ssh-pass.png>)

* 安装Cloudera Manager后台Agent程序到各个节点，并继续

![agent安装](http://111.229.152.231/images/note/2019/cdh_install/install-agents.png)
![agent安装完毕](http://111.229.152.231/images/note/2019/cdh_install/install-agents-finish.png)

* 分发CDH的Parcel包

![Parcel包分发并安装到各节点](http://111.229.152.231/images/note/2019/cdh_install/install-parcels.png)

* 主机检查，确保所有检查项均通过

![主机检查](<http://111.229.152.231/images/note/2019/cdh_install/inspect-result-1.png>)
![主机检查结果](<http://111.229.152.231/images/note/2019/cdh_install/inspect-result-3.png>)

* 点击完成，进行服务安装向导

选择需要安装的服务

![服务安装选择](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting.png)
![服务安装选择--变更](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting-1.png)

* 集群角色分配

![集群角色分配](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting-2.png)

![集群角色分配--详细](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting-3.png)

* 数据库设置

设置完成后，点击“测试连接”，确认相应的数据库连接正常

![数据库设置](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting-4.png)

* 目录设置

存储目录的大小和路径设置，完成后点击继续

![目录设置](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting-8.png)

* 服务启动

![集群服务启动](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting-6.png)
![集群服务启动完成](http://111.229.152.231/images/note/2019/cdh_install/cluster-setting-7.png)

* 安装完成

![安装完成](http://111.229.152.231/images/note/2019/cdh_install/finish_install.png)

* 进入home界面

## 参考

[1][Linux swappiness参数设置与内存交换](http://blog.sina.com.cn/s/blog_13cc013b50102wskd.html)
[2][linux实现开机自启动脚本](https://www.cnblogs.com/dpf-learn/p/7783314.html)
[3][如何在Redhat7.4安装CDH5.16.1](https://blog.csdn.net/Hadoop_SC/article/details/84748604)
