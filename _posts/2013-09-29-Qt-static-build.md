---

layout: post
title: Windows系统中Qt creator静态编译
date: 2013-09-29 18:53:48
tags: Qt creator, static build
category: try_out

---

* 开发环境: windows xp
* QT版本: qt2010.05

Qt默认的编译方式是动态编译的，但是有时候你编写的程序要发布出去，带很多动态库文件是很繁琐的，此时就需要静态编译你的程序，Qt要实现静态编译必须库文件也是静态编译的。

1. 在开始菜单里找到Qt Command Prompt并运行，输入命令
    configure -static -release -no-exceptions -L "C:\Qt\2010.05\qt\include"
    -L "C:\Qt\2010.05\qt\lib"

 > -L 指定头文件和链接动态库的路径，防止使用VC的头文件

2. 上述命令运行时，选择开源: 0; 选择license: y;

3. 上面的命令运行成功后现输入命令: mingw32-make sub-src

 > 上面的命令只执行编译sub-src目录下的文件，要不然编译的时间更长;
 >
 > 一开始我直接执行mingw32-make，但编译过程中出现错误，后来运行上面的命令成功，就暂时没管了

4. 上面的命令执行完之后，已经完成编译了

5. 相应的项目文件上要加上 **QMAKE_LFLAGS = -static** ，并重新运行 *qmake* 后，再进行编译，就可以得到一个不依赖于相关动态库的exe可执行文件了，但该文件相对较大，可以使用相应的工具对文件进行压缩，我用的upx来压缩exe可执行文件。

