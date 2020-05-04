---
title: nginx-rtmp流媒体服务使用
date: 2020-05-04 13:04:00
category: Video
tags: Video, nginx, rtmp, hls
layout: post
---

# nginx-rtmp安装和测试

## 一、环境准备

* 安装 pcre-devel 和 openssl-devel
```
yum install -y pcre pcre-devel openssl openssl-devel
```

* 下载源代码包
```
cd /opt
mkdir nginx-rtmp
cd nginx-rtmp
mkdir nginx-deploy
wget http://nginx.org/download/nginx-1.18.0.tar.gz
git clone git@github.com:arut/nginx-rtmp-module.git
```

* 解压编译安装源代码包
```
tar zxvf http://nginx.org/download/nginx-1.18.0.tar.gz
cd nginx-1.18.0
./configure --prefix=/opt/nginx-rtmp/nginx-deploy --add-module=/opt/nginx-rtmp/nginx-rtmp-module
make && make install
```

## 二、nginx 配置

* 新增加以下的配置信息

```conf
rtmp {
        server {
                listen 1935;
                chunk_size 4096;

                application live {
                        live on;
                        record off;
                }

                application hls {
                        live on;
                        hls  on;
                        hls_path /tmp/hls;
                        hls_fragment 5s;
                }
        }
}
```

* 在原来的http的配置内部，增加以下的配置信息

```conf
        location / {
            root /opt/nginx-rtmp/nginx-http-flv-module/test/www;
        }

        location /stat {
            rtmp_stat all;
            rtmp_stat_stylesheet stat.xsl;
        }

        location /stat.xsl {
            root /opt/nginx-rtmp/nginx-http-flv-module;
        }

        location /control {
            rtmp_control all;
        }

        location /rtmp-publisher {
            root /opt/nginx-rtmp/nginx-http-flv-module;
        }

        location /hls {
            types {
                application/vnd.apple.mpegurl m3u8;
                video/mp2t ts;
            }

            root /tmp;
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
```

## 三、多视频播放（多房间推流）

在 rtmp 推流的地址基础上，增加 串流密钥（房间号），下图是使用 OBS 推流的设置页面， 100 为串流密钥（房间号），根据自己的需要设置

![OBS设置-LIVE](http://111.229.152.231/images/note/2020/nginx-rtmp/obs-push-flow-setting-live.png)

播放客户端在访问时，需要在 rtmp 推流的地址基础上，增加 串流密钥（房间号），才可以取得相应码流，以上面的设置为例，对应的取流地址为 **rtmp://ip:1935/live/100**

## 四、HLS 播放设置

参照上面多视频播放截图上中设置，将 rtmp 推流地址中的 **live** 替换成 **hls**，如下图所示

![OBS设置-HLS](http://111.229.152.231/images/note/2020/nginx-rtmp/obs-push-flow-setting-hls.png)

对应的HLS播放地址为 **http://ip:1935/hls/100.m3u8**

## 五、问题汇总

* 播放HLS流出现跨域访问 No Access-Control-Allow-Origin 的问题，参照上面 **nginx配置** 中的 HLS 部分的配置方式， **/hls** 对应的配置中，增加以下的以下的配置项：

```conf
add_header Access-Control-Allow-Origin *;
```


## 参考
1. [HLTML5播放HLS流(.m3u8文件)出现 跨域访问 No Access-Control-Allow-Origin的解决方案](https://blog.csdn.net/the_victory/article/details/79666702)
2. [rtmp / http-flv / hls 协议配置 及跨域问题](https://www.cnblogs.com/yjmyzz/p/srs_study_2_hls_rtmp_httpflv_and_cross-domain.html)
3. [在CentOS上利用 nginx + nginx-rtmp-module 搭建基于HLS协议的直播服务器](https://blog.csdn.net/superyu1992/article/details/81204539)
4. [nginx-rtmp多房间和授权实现](https://blog.csdn.net/wei389083222/article/details/78721074/)

