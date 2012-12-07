---
title: libjpeg 编译安装及性能对比
date: 2012-12-07 17:12:52
slug: 2012/12/07/install-and-compare
category: problems
tags: libjpeg, libjpeg-turbo
layout: post

---

## libjpeg编译安装

[libjpeg][1] 即IJG开发的JPEG图片解压、压缩及其他工具的一个开源库，使用C语言编写。以前在windows上使用IJL来完成JPEG图片的解压和压缩，现在换到Linux下，在网上找了一下，发现 [libjpeg][1] 这个开源库，于是上他们的网站把源代码下回来，自己编译来试用一下，目前最新的版本是2012.01.15发布的8d。

在终端下输入以下命令来编译

        ./configure --enable-shared CFLAGS='-O2'
        make && make install

根据install.txt的说明，默认是使用-g编译的，加了**CFLAGS='-O2'**可以去除相关调试信息，减少目标动态库的大小。make install默认将编译好的动态库和静态库安装在/usr/local相应的bin, lib, include, man目录下。

## libjpeg性能对比

对比的对象及方法--解压和压缩2592 * 1920分辨率的图片，原图大小为2.63Mb
* libjpeg自行编译版本
* libjpeg Ubuntu-1204版本
* libjpeg-turbo编译版本

* libjpeg自行编译版本用时约160ms;
* libjpeg系统自带版本用时约100ms;
* libjpeg-turbo用时约85ms;

跟 [libjpeg-turbo][2] 网站上说明的，libjpeg-turbo效果是libjpeg的2~4倍基本一致。关于libjpeg-turbo的介绍，详细见他们的网页。以后自己弄的东西就用libjpeg-turbo了，系统还是用自带的吧，毕竟效率差异还不大。

回头再试一下同一张图片在windows上用IJL的效率如何。记得以前用DM368来压缩5Mb 2448 * 2048分辨率的图片，用时60ms左右，看来硬件加速还是牛B一点。

如果你也测试了这方面的东西，希望能告诉我了一下，能及时更新。

[1]: www.ijg.org
[2]: www.libjpeg-turbo.org
