---
title: 基于ffmpeg接入rtsp流并转推RTMP流
date: 2020-08-13 11:35:26
category: video
tags: ffmpeg, video, rtmp, rtsp
layout: post
---

本文记录基于 ffmpeg 的推流器，通过 rtsp 方式从输入端流媒体服务器拉流，再通过 rtmp 方式推流到输出端的流媒体服务器，如下图所示的流程：

![ffmpeg 框架](<http://111.229.152.231/images/note/2020/ffmpeg/ffmpeg-pull-push.png>)

## 拉流及推流的流程

程序的拉流和推流的流程见下面的流程图所示：

![ffmpeg 处理流程](<http://111.229.152.231/images/note/2020/ffmpeg/ffmpeg-loop.png>)

* avformat_network_init：因使用了网络进行拉流和推流处理，需要先初始化；如只是本地的文件处理，不需要初始化网络。
* avformat_alloc_output_context2：指定输出格式的名称为 **flv**

## 源代码

```c
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>

#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#include "libavformat/avio.h"

typedef struct
{
        AVFormatContext         *ic;
        AVFormatContext         *oc;
        int                     video_stream_index;
        double duration;
        int                     initialized;
} priv_info;

/*
 * 打开视频源和视频接收端
 */
static int open_device(priv_info *priv, const char *input_url, const char *output_url)
{
        int ret = -1;
        do {
               priv->ic = avformat_alloc_context();

                AVDictionary* options = NULL;
                av_dict_set(&options, "rtsp_transport", "tcp", 0);  //强制使用tcp，udp在1080p下会丢包导致花屏
                av_dict_set(&options, "stimeout", "10000000", 0);
                //av_dict_set(&options, "buffer_size", "1024000", 0);  //设置udp的接收缓冲
                av_dict_set(&options, "flvflags", "no_duration_filesize", 0);

                if (avformat_open_input(&priv->ic, input_url, NULL, &options) < 0) {
                        printf("could not open input file.\n");
                        return -1;
                }

                if (avformat_find_stream_info(priv->ic, NULL) < 0) {
                        printf("could find stream information\n");
                        return -1;
                }

                av_dump_format(priv->ic, 0, input_url, 0);

                avformat_alloc_output_context2(&priv->oc, NULL, "flv", output_url);
                if (priv->oc == NULL) {
                        printf("could not deduce format from file extension\n");
                        break;
                }

                priv->video_stream_index = -1;
                unsigned int i = 0;
                for (; i < priv->ic->nb_streams; i++) {
                        if (priv->ic->streams[i]->codecpar->codec_type ==
                                        AVMEDIA_TYPE_VIDEO) {
                                priv->video_stream_index = i;
                                break;
                        }
                }

                if (priv->video_stream_index == -1) {
                        printf("can not find a video stream\n");
                        return -1;
                }


                AVStream *input_stream = priv->ic->streams[priv->video_stream_index];

                AVRational frame_rate = av_guess_frame_rate(priv->ic, input_stream, NULL);
                printf("frame_rate %d\n", frame_rate.num);
                priv->duration = ((frame_rate.num && frame_rate.den) ?
                                        av_q2d((AVRational){frame_rate.den, frame_rate.num}) : 0);

                AVCodec *codec = avcodec_find_decoder(input_stream->codecpar->codec_id);
                AVStream *output_stream = avformat_new_stream(priv->oc, codec);
                if (output_stream == NULL) {
                        printf("Failed to allocating output stream\n");
                        break;
                }

                if (avcodec_parameters_copy(output_stream->codecpar, input_stream->codecpar) < 0) {
                        printf("Failed to copy context input to output stream codec context\n");
                        break;
                }

                output_stream->codecpar->codec_tag = 0;

                av_dump_format(priv->oc, 0, output_url, 1);

                if (!(priv->oc->flags & AVFMT_NOFILE)) {
                        if (avio_open(&priv->oc->pb, output_url, AVIO_FLAG_WRITE) < 0) {
                                break;
                        }
                }

                if (avformat_write_header(priv->oc, NULL) < 0) {
                        break;
                }

                ret = 0;

        } while(0);

        if (ret == -1) {
	        avformat_close_input(&priv->ic);

                if (!(priv->oc->flags & AVFMT_NOFILE)) {
                        avio_close(priv->oc->pb);
                }

                avformat_free_context(priv->oc);

                priv->oc = NULL;
                priv->ic = NULL;

                priv->video_stream_index = -1;
                priv->initialized        = 0;
        }

        return ret;
}

/*
 * 从视频源读一帧视频并转发
 */
static int output_stream(priv_info *priv, int count)
{
        AVPacket avpkt;
        av_init_packet(&avpkt);
        int ret = -1;

        do {
                if (av_read_frame(priv->ic, &avpkt) < 0) {
                        break;
                }

                if (avpkt.stream_index != priv->video_stream_index) {
                        printf("not video stream\n");
                        ret = 1;
                        break;
                }

                if (priv->ic->streams[avpkt.stream_index]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
                        av_usleep((int64_t)(priv->duration * AV_TIME_BASE));
                }

                av_packet_rescale_ts(&avpkt, priv->ic->streams[priv->video_stream_index]->time_base,
                                        priv->oc->streams[priv->video_stream_index]->time_base);
                /* 第一帧强制修改 pts、dts 为０ */
                if (count == 0) {
                        avpkt.pts = 0;
                        avpkt.dts = 0;
                }
                avpkt.pos = -1;

                if (av_interleaved_write_frame(priv->oc, &avpkt) < 0) {
                        break;
                }

                ret = 0;

        } while(0);

        /* 释放单帧视频资源 */
        av_packet_unref(&avpkt);

        return ret;
}

/*
 * 释放视频转发已申请的资源
 */
static void release_resource(priv_info *priv)
{
        if (priv->initialized == 0) {
                return;
        }

        av_write_trailer(priv->oc);
	    avformat_close_input(&priv->ic);

        if (!(priv->oc->flags & AVFMT_NOFILE)) {
                avio_close(priv->oc->pb);
        }

        avformat_free_context(priv->oc);

        priv->oc        = NULL;
        priv->ic        = NULL;

        priv->video_stream_index = -1;
        priv->initialized        = 0;
}

/*
 * 主程序
 */
int main(int argc, char **argv)
{
        if (argc < 3) {
            printf("usage: %s input output\n", argv[0]);
            return -1;
        }

        input_url  = argv[1];
        output_url = argv[2];

        priv_info *priv = (priv_info *)calloc(1, sizeof(priv_info));
        int count = 0;

        av_register_all();
        avformat_network_init();

        while (thiz->thread_status) {
                if (priv->initialized == 0) {
                        if (open_device(priv, input_url, output_url) == 0) {
                                priv->initialized = 1;
                                count = 0;
                        } else {
                                continue;
                        }
                }

                if (output_stream(priv, count) < 0) {
                        release_resource(priv);
                        continue;
                }
                count++;
        }

        release_resource(priv);

        avformat_network_deinit();
        free(priv);
        priv= NULL;

        return 0;
}
```

## 需要注意的地方

* 封装格式：RTMP采用的封装格式是 FLV，在指定输出流媒体的时候，需要指定其封闭格式为 **flv**
* 其他流媒体协议也需要指定其封装格式，如 UDP 推送流媒体的时候，可指定封装格式为 **mpegts**
* 关于时间戳问题：参照 雷神 和 叶余 的文章处理，都出现第一帧时间戳晚于第二帧时间戳的情况，所以程序在收到第一帧时，将 dts 和 pts 置为 0。

## 参考

1. [FFmpeg流媒体处理-收流与推流](https://www.cnblogs.com/leisure_chn/p/10623968.html)
2. [FFmpeg时间戳详解](https://www.cnblogs.com/leisure_chn/p/10584910.html)
3. [最简单的基于FFmpeg的推流器（以推送RTMP为例）](https://blog.csdn.net/leixiaohua1020/article/details/39803457)
4. [基于FFmpeg进行RTMP推流（一）](https://www.jianshu.com/p/69eede147229)
5. [基于FFmpeg进行RTMP推流（二）](https://www.jianshu.com/p/6b9ab2652147)
6. [深入理解pts，dts，time_base](https://blog.csdn.net/bixinwei22/article/details/78770090)
7. [最简单的基于FFMPEG的封装格式转换器（无编解码）](https://blog.csdn.net/leixiaohua1020/article/details/25422685)
8. [FFmpeg转封装(remuxing)](https://www.jianshu.com/p/7506c2799ecb)
9. [FFmpeg学习目录](https://www.jianshu.com/p/015fcf9572a0)
