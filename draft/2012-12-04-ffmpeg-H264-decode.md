---
title: ffmpeg 解码H264码流
date: 2012-12-07 17:12:52
slug: 2012/12/04/ffmpeg-H264-decode
category: problems
tags: ffmpeg, H264
layout: post

---

## Ubuntu 12-04 编译ffmpeg

首先要安装yasm，ffmpeg中部分代码用汇编来实现，所以速度上还是比较快的。先安装 **yasm**，再执行 **configure**，最后 **make和make install**。

        sudo apt-get install yasm
        ./configure --enable-shared --disable-debug --enable-memalign-hack
        make && make install

**make install** 的时候可能提示没有权限，你懂的，ubuntu下要**sudo**。
默认情况下的configure是不支持生成动态库的，所以上面加了**--enable-shared**


## ffmpeg解码H264码流
