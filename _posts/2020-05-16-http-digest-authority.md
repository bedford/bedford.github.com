---
title: HTTP摘要认证Digest
date: 2020-05-16 17:26:52
category: HTTP
tags: HTTP, protocol, Digest
layout: post
---

## 一、什么是摘要认证

摘要认证（Digest）是为了修复 [基本认证](https://www.cnblogs.com/xiaoxiaotank/p/11009796.html) 存在的缺陷而产生的，摘要认证过程中，不采用明文的方式发送密码，提高了通信的安全性。

摘要认证过程的流程图如下：

![摘要认证流程图](http://111.229.152.231/images/note/2020/http-digest/digest-workflow.png)

参数说明:
* www-Authentication：说明使用的哪种方式进行认证（Basic，Digest等）
* realm：领域、范围，即该认证用来访问哪什么服务
* qop：保护质量
* nonce：服务器向客户端发送随机数，客户端计算摘要时需要使用该字段，多次生成同一个用户的摘要时，计算摘要结果会不同
* nc：nonce计数器，表示同一个客户端发送出请求的数量
* cnonce：客户端产生的随机数，并在认证请求时上报给服务端，可用于核验对方的身份
* response：客户端计算出的一个字符串，以证明用户知道该用户的密码

## 二、摘要认证过程测试

* 打开需要访问的URL
* 服务端返回未认证，并弹窗要求输入用户名和密码
![登录窗口](http://111.229.152.231/images/note/2020/http-digest/login-windows.png)
* 根据服务端返回的realm、qop、nonce，客户端计算生成response
* 再次打开需要访问的URL
* 服务端返回认证成功

![网络抓包过程通讯过程](http://111.229.152.231/images/note/2020/http-digest/digest-test-flow.png)

## 三、response计算过程

摘要认证的response计算公式如下：

    MD5(MD5(A1):<nonce>:<nc>:<conce>:<qop>:MD5(A2))

其中A1和A2分别包含以下的信息：

| 名称 | 内容                            |
|----|-------------------------------|
| A1 | \<username\>:\<realm\>:\<password\> |
| A2 | \<request-method\>:\<uri\>       |


## 参考
1. [HTTP认证之摘要认证——Digest](https://www.cnblogs.com/xiaoxiaotank/p/11078571.html)
2. [HTTP 基本认证&摘要认证](https://www.jianshu.com/p/3bb3d6ecb76a)
3. [摘要认证及实现HTTP digest authentication](https://blog.csdn.net/t1269747417/article/details/86038128)

