---

layout: post
title: CloneZilla再生龙安装定制系统
date: 2013-05-10 13:35:34
tags: CloneZilla, ISO, grub
category: try_out

---

[CloneZilla再生龙][1] 是台湾 [國網中心][2] 开发的一款软件,
功能上类似于GHOST，可以进行硬盘到硬盘、分区到分区的备份和恢复，而且支持Linux系统,更多的介绍请到他们的网页上查阅。

我使用CloneZilla主要是完成自己定制的系统安装，以前尝试过以下的两种方法：

* 自行制作一个ramdisk、移植内核到U盘中做成启动盘，通过U盘启动ramdisk，再由ramdisk来执行相应的安装脚本，实现将定制系统安装到目标板的功能。
* 利用GHOST把定制好的系统做全盘备份，再复制到目标板上

第一种方法通过dd的方式把数据和安装系统写入U盘，耗时比较久;
如何要修改定制系统的东西，要重新dd写入一次，来回折腾比较久，而且相应的内核一般不具有通用性(当然也可以做得比较通用，那ramdisk就相对大一些)

说实话，本来是想用第二种方法的，但不知道是不是我分区上有问题，在GHOST备份的时候说分区上异常，折腾了几次分区，还是无功而返，所以寻求其他的方法。

在朋友那了解到CloneZilla，回来下载了一个最新的版本，试了一下感觉还不错，CloneZilla功能比较强大，我只用了其中的livecd部分，可以通过内置的命令和定制的脚本，生成一个livecd，该livecd可以自动执行用户定制的脚本，从而可以实现自动安装系统到目标板的需要。

具体的操作步骤见 [CloneZilla定制livecd][3], 用户定制脚本可以参照相应的custom-ocs样例来写，custom-ocs就跟写平常的shell脚本一样，再执行ocs-iso命令来生成livecd。将livecd写到U盘中，并将U盘制作成启动盘即可。

---
[1]: http://clonezilla.nchc.org.tw/intro
[2]: http://www.nchc.org.tw/tw/
[3]: http://clonezilla.nchc.org.tw/clonezilla-live/#make_custom_clonezilla_live
