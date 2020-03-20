---
title: Python实现HTTP请求
date: 2020-03-21 07:32:00
category: HTTP
tags: HTTP, python, requests
layout: post
---

## 一、四种常见POST请求

requests是使用python编写实现的http库，支持使用cookie保持会话，支持文件上传，支持自动响应内容的编码，支持国际化的URL和POST数据自动编码。

requests会自动实现持久连接keep-alive

针对HTTP的POST请求，以下对Content-Type的四种格式使用requests实现进行说明。

### 1.1 application/x-www-form-urlencoded 格式

application/x-www-form-urlencoded是POST请求最常见，也是默认的格式。它要求数据字段名称和值之间以等号连接，与另一组数据字段之间用&连接；以form表单形式提交数据。

```
param1=1&param2=2
```

以下是使用requests的示例代码

```python
data = {'param1':'1', 'param2':'2'}
result = requests.post('http://127.0.0.1', data)
```

如使用类来组织请求参数，请参照以下的示例代码

```python
class ReqParams:
    def __init__(self, param1, param2):
    self.param1 = param1
    self.param2 = param2

data = ReqParams(1, 2).__dict__
result = requests.post('http://127.0.0.1', data)
```

### 1.2 application/json 格式

application/json 格式的请求头部用于通知服务器，通过POST请求提交的消息主体（body）是序列化后的JSON字符串。以下是使用requests的示例代码

```python
data = {'param1':'1', 'param2':'2'}
result = requests.post('http://127.0.0.1', json.dumps(data))
```

如使用类来组织请求参数，请参照以下的示例代码

```python
class ReqParams:
    def __init__(self, param1, param2):
    self.param1 = param1
    self.param2 = param2

data = ReqParams(1, 2).__dict__
result = requests.post('http://127.0.0.1', json.dumps(data))
```

### 1.3 text/xml 格式

text/xml 格式的请求头部用于通知服务器，通过POST请求提交的消息主体（body）是序列化后的 xml 字符串。以下是使用requests的示例代码

```python
xml = """my xml"""
headers = {'Content-Type': 'application/xml'}
requests.post('http://127.0.0.1', data=xml, headers=headers)
```

### 1.4 multipart/form-data 格式

multipart/form-data 格式应用于文件上传功能的表单，以下是使用requests的示例代码

```python
url = 'http://127.0.0.1'
upload_file = {'file': open('C://Users//Administrator//Desktop//test.jpg', 'rb')}
result = requests.post(url, files=upload_file)
```

## 二、GET请求

### 2.1 无参数实例

```python
url = 'http://127.0.0.1'
result = requests.get(url)
```

### 2.2 有参数实例

我们可以通过程序将参数按 GET 请求的要求，使用字符串拼接的方式来完成参数的拼接，也可以将参数以字典的形式，传入给 requests，由 requests 完成转换的工作。

```python
data = {'param1':'1', 'param2':'2'}
result = requests.get('http://127.0.0.1', params=data)
```

如使用类来组织请求参数，请参照以下的示例代码

```python
class ReqParams:
    def __init__(self, param1, param2):
    self.param1 = param1
    self.param2 = param2

data = ReqParams(1, 2).__dict__
result = requests.get('http://127.0.0.1', params=data)
```

## 参考
1. [Python-requests模块详解](https://www.cnblogs.com/lanyinhao/p/9634742.html)
2. [Requests: HTTP for Humans](https://requests.readthedocs.io/en/master/)

