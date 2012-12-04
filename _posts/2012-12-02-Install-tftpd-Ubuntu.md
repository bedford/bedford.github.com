---
title: Ubuntu-12-04 安装 tftp 服务器
date: 2012-12-02 23:36:34
slug: 2012/12/02/Install-tftpd-Ubuntu
category: problems
tags: tftpd, xinetd, inetd
layout: post

---

以前也写过类似的文档，但每次需要的时候，总是找不到，虽然是很简单，但不可能记得住那些配置项，后来直接把安装的过程写到一个脚本里，放到github上。现在也顺便记录一下需要完成的工作。

tftpd这个服务，在新的Ubuntu系统中，都通过 [xinetd][1] 这个服务来启动的;老一些版本的系统是通过 [inetd][1] 服务来启动的。新版本的系统默认已经安装了xinetd服务，所以也是基于xinetd方式来介绍。

需要安装的软件包： **tftp** 和 **tftpd** 执行以下的命令来安装tftp和tftpd服务:

        sudo apt-get install tftp tftpd

接着，在/etc/xinetd.d目录下建立一个tftp的文件,在文件中输入以下内容：


	service tftp
	{
		socket_type = dgram
		protocol = udp
		wait = yes
		user = root
		server = /usr/sbin/in.tftpd
		server_args = -s /tftpboot
		disable = no
		per_source = 11
		cps = 100 2
		flags = IPv4
	}

再创建tftp服务文件目录，要跟上面配置中设备的 **server_args** 项中的路径一致。

        sudo mkdir /tftpboot
        sudo chmod 777 -R /tftpboot

最后，重新启动xinetd服务

        sudo /etc/init.d/xinetd restart

[1]: http://blog.sina.com.cn/s/blog_4c5e22a30100oalf.html
