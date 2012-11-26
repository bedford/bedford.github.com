---
title: Putty ssh autologin
layout: post
date: 2012-07-29 22:30
tags: putty, ssh, key
category: problems

---

原来一直在使用SecureCRT远程通过ssh登录虚拟机的ubuntu，不知道什么原因，突然间想着把工具都尽量换成开源的，不再使用盗版的软件，至少我手提电脑上的window7是正版的，即使是OEM版本，不再像以前那样使用盗版的xp系统。

Putty是我在使用SecureCRT之前使用的终端，但在使用串口时经常USB转串口会死掉、不支持多标签、不支持自动登录，就换成了盗版的SecureCRT。倒回来使用putty后，第一件想到要处理的怎么处理自动登录的问题;可能当时自己没有找相应的方法吧，原来要让putty支持自动登录简单设置一下就好了。第二个问题是多标签，我现在使用MTPuTTY来实现windows上的多标签，使用screen来实现终端下的多窗口，也试过tmux，可能是libevent版本较低的原因，tmux运行一小会之后，CPU的占用率还挺高的，特别是多个窗口之间来回切换多次之后，而且screen对于而言基本够用了。至于串口的问题，暂时未定位好原因。

下面终于进入正题，讲一下怎么配置putty和服务器端:

1. 在服务器端生成ssh的key，我使用了登录github的key，执行以下命令后，在~/.ssh目录下就生成了id_rsa和id_rsa.pub两个文件，其中前者是私有key，后者是公有key，以下的 **your_email@yourmail.com** 根据自己实际的email来填写。

        ssh-keygen -t rsa -C "your_email@yourmail.com"

2. 在服务器.ssh目录下创建一个public key，命名为authorized_keys

        cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

3. 将私钥导出来到windows系统，可以通过psftp工具将私有key导出到windons系统。

4. 创建windows端的私钥(因为putty产生的key跟Linux系统下open ssh产生的key不匹配)

        * 打开puttygen
        * 点"load"按钮，选中上一步导出来的私钥
        * 点"Save private key"，保存新的私钥

5. 打开putty，加载所需的会话

        * 点"Connection"选项，输入"Auto-login usename"
        * 点"Connection"-->"SSH"-->"Auth"选项，选中上一步生成的私钥

6. 保存会话的设置

7. 双击刚修改完的会话，你会发现putty已经可以自动登录了


#####参考:

1.[putty openssh tips](www.unixwiz.net/techtips/putty-openssh.html)
2.[使用密钥对让putty(ssh)自动登录](www.chinaunix.net/old_jh/245314.html)
