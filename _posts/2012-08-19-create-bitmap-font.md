---

layout: post
title: 由矢量字体生成点阵字体
date: 2012-08-19 14:04:34
tags: TrueType, bitmap, bdf, pcf, ttc
category: problems

---


## 字体的分类

我们日常用的字体分为 [点阵字体][1] 和 [矢量字体][2] 两种。

点阵字体在进行缩放处理后，显示的效果不理想是它的弊端所在; 点阵字体在显示上比矢量字体的处理处简单，特别在一些嵌入式设备上，点阵字体的使用会更多一些。

[矢量字体][2] 的每个字形都是通过数学方程来描述的，一个字形上区分出若干个关键点，相邻关键点之间由一条光滑曲线连接，这条曲线可以由有限个参数来唯一确定。矢量字体的好处是字体经过缩放后不会产生变形。但在使用时要增加通过数学方程将对应的点阵信息计算出来的工作量。


## 矢量字体组成

大部分的矢量字体由内嵌的点阵字体和字体描述方程信息组成。当字体大小小于一定值时使用点阵字体(20 * 20 pixel或以下)，而不使用字体描述方程来计算字体的点阵信息; 当字体较小时，通过缩小向量的方法会使很多笔画重叠在一起，这样可能出现字体无法辨认的情况。


## 由TrueType字体生成指定大小点阵字体

###### 测试环境

* TrueType字体:wqy-zeihei.ttc
* 系统: Ubuntu 12-04
* 字体大小:32 * 32pixel

Linux下可以通过工具otf2bdf实现从ttf、ttc字体文件到指定字体大小的bdf字体文件的转换，Ubuntu系统可以通过以下命令安装otf2bdf工具

        `sudo apt-get install otf2bdf`

执行以下命令，可以将当前目录下的wqy-zeihei.ttc转换成对应的大小为32 * 32pixel的 [点阵字体][1]

        `otf2bdf -p 24 wqy-zeihei.ttc -o wqy-zeiehi.bdf`

其中 **-p 24** 表示字体大小为24pt;otf2bdf工具中设定的字体大小单位为pt，而不是我们常见的px(pixel);关于pt和px的相关介绍请参见 [pt和px的区别][3]

默认DPI(Dot per inch，每英寸的点数)为96的情况下，px = pt * DPI / 72，即

        `px = 96 * pt / 72 = 4 * pt / 3;`

所以要获得大小为32 * 32pixel的字体库，使用otf2bdf时，设置的 **-p** 参数为 **24** 。

bdf是原始的点阵字体文件，可以通过工具bdftopcf将其转换成pcf字体文件。Ubuntu系统可以通过以下命令来安装bdftopcf工具

        `sudo apt-get install bdftopcf`

执行以下命令可以将bdf字体文件转换成pcf字体文件，pcf字体文件是bdf字体文件的一半大小

        `bdftopcf -o wqy-zeihei.pcf wqy-zeihei.bdf`


### 后记

后来发现gbdfed这个有GUI界面的工具，可以实现从矢量字体库到bdf的转换功能，使用起来比otf2bdf更直观一些。

如果大家有更多的发现，请告知。



[1]: zh.wikipedia.org/wiki/点阵字体
[2]: zh.wikipedia.org/wiki/矢量字体
[3]: www.cnblogs.com/chinhr/archive/2008/01/23/1049576.html

