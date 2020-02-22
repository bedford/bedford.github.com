---
title: HTTP协议浅出
date: 2020-02-23 00:26:52
category: HTTP
tags: HTTP, protocol
layout: post
---

因在整理其他单位提供的接口文档时，对HTTP协议的实体（Body）部分的类型对应不清楚，找资料进行确认的过程中，在跟着 饶全成的 [深度解密HTTP通信细节](https://mp.weixin.qq.com/s/NUW0sLBMTglnIbN7OHkdoQ) 熟悉HTTP通信过程和细节的过程中，对HTTP协议理解的简单记录，并通读了 [图解HTTP](https://book.douban.com/subject/25863515/) 第1-6章的内容，把相关内容结合并重新整理而来。

## HTTP访问过程
当我们在网页浏览器的地址栏输入URL，并按下确定后，信息会根由浏览器到我们访问的服务器，服务器将信息返回给浏览器，浏览器将信息渲染并显示出来。
![http_process](http://111.229.152.231/images/note/2020/http-protocol/http_process.png)

在这个过程中，浏览器和服务器之间，通过 HTTP 协议（HyperText Transfer Protocol，超文本传输协议），完成两者间的信息交互通信。HTTP是TCP/IP四层模型中的应用层协议。

当通过http发起一个请求时，应用层、传输层、网络层和链路层的相关协议依次对该请求进行包装并携带对应的首部，最终在链路层生成以太网数据包，以太网数据包通过物理介质传输给服务器，服务器接收到数据包以后，然后再一层一层采用对应的协议进行拆包，最后把应用层数据交给服务程序处理。

网络通信就好比送快递，商品外面的一层层包裹就是各种协议，协议包含了商品信息、收货地址、收件人、联系方式等，然后还需要配送车、配送站、快递员，商品才能最终到达用户手中。

一般情况下，快递是不能直达的，需要先转发到对应的配送站，然后由配送站再进行派件。

配送车就是物理介质，配送站就是网关， 快递员就是路由器，收货地址就是IP地址，联系方式就是MAC地址。 

快递员负责把包裹转发到各个配送站，配送站根据收获地址里的省市区，确认是否需要继续转发到其他配送站，当包裹到达了目标配送站以后，配送站再根据联系方式找到收件人进行派件。  


### 应用层
应用层定义了多种协议来规范数据格式，如HTTP、FTP（File Transfer Protocol）、SMTP，定义数据格式并按照对应的格式解码，易于被程序识别。

### 传输层
传输层提供处理网络连接中的两台计算机之间的数据传输；在传输层有两个性质不同的协议：TCP（Transmission Control Protocol，传输控制协议）和 UDP（User Data Protocol，用户数据报协议）。
传输层要求应用程序都需要指定端口号进行数据传输，来标识不同的应用程序。
TCP协议有三次握手机制，HTTP协议在传输层采用TCP协议来传输数据。

### 网络层
网络层用来处理在网络上流动的数据包。IP数据包是网络传输的最小数据单位，该层规定了通过什么路径（传输路线）将数据送达对端。网络层所起的作用是在众多的网络传输路线中选择其中一条传输路线。
网络层通过IP协议、ARP协议和路由协议，定义网络地址、区分网段、子网内MAC寻址，对于不同子网的数据包进行路由。

### 链路层
链路层用于处理连接网络的硬件部分，包括控制操作系统、设备驱动、网卡、光口等硬件设备。该层定义了以太网协议，规范每一组传输的电信号，按帧来将数据分包。

## HTTP协议特性
### HTTP端口
* http默认使用80端口
* https默认使用443端口

### 无状态（stateless）
HTTP协议自身不对请求和响应之间的通信状态进行保存。HTTP/1.1引入了Cookie技术，利用Cookie技术，在客户端保存Cookie信息，并在向服务器请求时携带Cookie信息，便于服务器端管理客户端的状态。

### 资源定位URI
HTTP协议使用URI定位互联网上的资源。URI（Uniform Resource Identifier，统一资源标识符）用字符串标识某一互联网资源，URL（Uniform Resource Locator，统一资源定位符）表示资源的地点（互联网上所处的位置），URN(Uniform Resource Name，统一资源名)，表示资源的名称；URI是一个通用的概念，由两个主要的子集URI和URN构成。
* URL通过转义符，使用US-ASCII字符集有的限子集对任意字符或数据进行编码
* URL在传输过程中进行了非“安全字符”编码（中文字符，先进行UTF8编码，再进行非“安全字符”编码 URLEncode）

### 持久化
HTTP/1.1 增加了持久连接（keep-alive）的方法，只要任意一端没有明确提出断开连接，则保持TCP连接状态。通过持久化，减少连接的断开和重连的操作，提高连接的效率；通过连接的并发，也可以提高通信的效率；（通常浏览器对一个页面的默认最大并发连接是4个）。

## HTTP报文
HTTP协议交互的信息称为HTTP报文，客户端发出的HTTP报文称为请求报文，服务器端返回的报文称为响应报文。HTTP报文由多行数据构成，多行之间以（CF+LF）作为换行符来区隔。

### 请求报文
请示报文的结构如下图所示：
![request](http://111.229.152.231/images/note/2020/http-protocol/request.png)
* 请求行的组成：请求方法 + 空格 ＋ URL ＋ 空格 ＋ 协议版本 ＋ 回车符 ＋ 换行符
* 请求头部的组成（请求头部可以由多行组成）：头部字段名: + 值 +  回车符 ＋ 换行符
* 空行：
* 请求数据（即body部分，可以为空）
### 响应报文
![request](http://111.229.152.231/images/note/2020/http-protocol/response.png)
* 响应行的组成：协议版本 + 空格 ＋ 状态码 ＋ 空格 ＋ 原因描述说明 ＋ 回车符 ＋ 换行符
* 响应头部的组成（响应头部可以由多行组成）：头部字段名: + 值 +  回车符 ＋ 换行符
* 空行：
* 响应数据（即body部分，可以为空）

### 头部类型及说明
| 首部字段名 | 说明 | 样例 |
|--------------------|-------------------------|------------------------------------------------------------|
| Connection | 管理持久连接 | Keep\-Alive |
| Date | 采用RFC1123中规定的日期时间的格式 | Date: Sat, 22 Feb 2020 15:23:27 GMT |
| Trailer | 分块传输的结束标记 | |
| Transfer\-Encoding | 规定传输报文主体时采用的编码方式 | Transfer\-Encoding:chunked |
| Accept | 客户端可以处理的媒体类型及媒体类型的相对优先级 | Accept：text/html |
| Accept\-Charset | 客户端支持的字符集及字符集的相对优先级顺序 | Accept\-Charset：iso\-8859\-5; |
| Accept\-Encoding | 客户端支持的压缩方式 | Accept\-Encoding：gzip, defalte |
| Accept\-Language | 客户端支持的语言集 | Accept\-Language: zh\-CN,zh;q=0\.9,en\-US;q=0\.8,en;q=0\.7 |
| Host | 告知服务器请求的主机名和端口号 | |
| Allow | 服务端通知客户端支持的HTTP方法 | |
| Content\-Encoding | body的压缩方式 | |
| Content\-Language | 服务端告知客户端，body使用的自然语言 | |
| Content\-Length | body的长度 | |
| Content\-MD5 | body的MD5校验值 | |
| Content\-Type | body的媒体类型 | |
| Expires | 资源失效时间 | |
| Set\-Cookie | 服务端返回需要在客户端缓存的Cookie值 | |
| Cookie | 客户端发送给服务端的Cookie值 | |

## HTTP方法
| 方法名 | 说明 |
|---------|-------------------------------------------------------------------------|
| GET | 提交的数据会放在URL之后，以?分割URL和传输的数据，参数之间用&连接，参数名和值之前用=连接，提交的数据大小有限制，最多只能有1024字节 |
| POST | 提交的数据放在HTTP包中的body部分，对提交数据的大小不作限制 |
| PUT | 传输文件，一般不使用 |
| HEAD | 获取报文头部 |
| DELETE | 删除文件，一般不使用 |
| OPTIONS | 查询支持的方法 |
| CONNECT | |

## HTTP返回码
| 返回码 | 类别 | 说明 |
|-----|------------------------|---------------|
| 1XX | Informational（信息性状态码） | 接收的请求正在处理 |
| 2XX | Success（成功状态码） | 请求正常处理完毕 |
| 3XX | Redirection（重定向状态码） | 需要进行附加操作以完成请求 |
| 4XX | Client Error（客户端错误状态码） | 服务器无法处理请求 |
| 5XX | Server Error（服务端错误状态码） | 服务器处理请求出错 |

## 参考
1. [深度解密HTTP通信细节](https://mp.weixin.qq.com/s/NUW0sLBMTglnIbN7OHkdoQ)
2. [图解HTTP](https://book.douban.com/subject/25863515/) 
3. [深入浅出TCP/IP协议](https://www.cnblogs.com/onepixel/p/7092302.html)
4. [互联网协议入门](http://www.ruanyifeng.com/blog/2012/05/internet_protocol_suite_part_i.html)
5. [mozilla的Web开发技术之HTTP篇](https://developer.mozilla.org/zh-CN/docs/Web/HTTP)
6. [HTTP协议超级详解](https://www.cnblogs.com/an-wen/p/11180076.html)
7. [百度百科http](https://baike.baidu.com/item/http/243074?fromtitle=HTTP%E5%8D%8F%E8%AE%AE)
8. [一篇比较全的HTTP协议详解](http://caibaojian.com/http-protocol.html)
