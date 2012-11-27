---

title: Ubuntu install Vmware tools
layout: post
date: 2012-08-04 14:35
tags: ubuntu-12.04, vmware
category: problems

---

今天把家里电脑的虚拟机ubuntu-12.04环境配置了一下，顺带记录一下。发现如果没有安装vmware tools时，虚拟机系统的时间老是跑得比较慢。


### vmware tools install

1.安装linux-headers

        sudo apt-get install linux-headers-3.2.0-23-generic-pae

2.安装build-essential

        sudo apt-get install build-essential

3.新版本的内核头文件组织跟 **vmware** 设定有区别，给相应的两个头文件创建软连接就可以

        cd /usr/src/linux-headers-3.2.0-23-generic-pae/include/linux
        ln -s ../generated/autoconf.h
        ln -s ../generated/utsrelease.h

4.点 vmware 界面中的 **Install Vmware tools** 菜单,虚拟机会将光盘挂载在 **/media** 目录下;把 **vmware tools** 安装包解压到 **/tmp** 目录下，再切换到 **vmware tools** 工具的根目录,执行安装脚本

        sudo ./vmware-install.pl

接下来就一直回车，直到安装完成。安装完成后，将虚拟光盘退出将可。 **/tmp** 目录下解压出来的 **vmware-tools** 目录会自动删除。之前用 **ubuntu-10.04** 时没有发现会自动删除的，要手动清除目录才行，看来新的 **vmware tools** 又改进了，更人性化。

