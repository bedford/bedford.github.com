---
title: ffmpeg获取基于rtsp的H264码流
date: 2013-10-13 09:12:52
category: problems
tags: ffmpeg, H264, rtsp
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

### 初始化

* 注册支持的文件格式和编码、解码器

        av_register_all();
        avcodec_register_all();

* 初始化网络多媒体文件格式

        avformat_network_init();

* 打开多媒体文件

        AVFormatContext *input_format_context = avformat_alloc_context();
        avformat_open_input(&input_format_context, media_filename, NULL, NULL);

* 获取并输出多媒体文件信息

        avformat_find_stream_info(input_format_context, NULL);
        av_dump_format(input_format_context, 0, media_filename, 0);

* 获取多媒体流/文件中的视频索引

        int video_stream_index = -1;
        for (unsigned int i = 0; i < input_format_context->nb_streams; i++) {
                if (input_format_context->streams[i]->codec->codec_type ==
                                                AVMEDIA_TYPE_VIDEO) {
                        video_stream_index = i;
                        break;
                }
        }

* 创建输出多媒体

        AVFormatContext *output_format_context = NULL;
        avformat_alloc_output_context2(&output_format_context, NULL, NULL, output_name);


* 编码器参数及时间戳参数设置

        AVStream *stream = avformat_new_stream(output_format_context, NULL);
        AVCodecContext *out_codec_context = stream->codec;

        out_codec_context->codec_id     = input_codec_context->codec_id;
        out_codec_context->codec_type   = input_codec_context->codec_type;

        if (!out_codec_context->codec_tag) {
                unsigned int codec_tag;
                if ((!output_format_context->oformat->codec_tag) ||
                                (av_codec_get_id(output_format_context->oformat->codec_tag,
                                                 input_codec_context->codec_tag)
                                 == out_codec_context->codec_id) ||
                                (!av_codec_get_tag2(output_format_context->oformat->codec_tag, 
                                                    input_codec_context->codec_id, &codec_tag))) {
                        out_codec_context->codec_tag = input_codec_context->codec_tag;
                }
        }

        out_codec_context->bit_rate     = input_codec_context->bit_rate;
        out_codec_context->rc_max_rate  = input_codec_context->rc_max_rate;
        out_codec_context->rc_buffer_size = input_codec_context->rc_buffer_size;
        out_codec_context->field_order    = input_codec_context->field_order;

        uint64_t extra_size = input_codec_context->extradata_size + FF_INPUT_BUFFER_PADDING_SIZE;
        out_codec_context->extradata      = av_mallocz(extra_size);
        memcpy(out_codec_context->extradata,
                        input_codec_context->extradata,
                        input_codec_context->extradata_size);
        out_codec_context->extradata_size= input_codec_context->extradata_size;

        out_codec_context->bits_per_coded_sample  = input_codec_context->bits_per_coded_sample;
        out_codec_context->time_base = input_codec_context->time_base;

        out_codec_context->pix_fmt      = input_codec_context->pix_fmt;
        out_codec_context->width        = input_codec_context->width;
        out_codec_context->height       = input_codec_context->height;
        out_codec_context->has_b_frames = input_codec_context->has_b_frames;
        output_format_context->streams[video_stream_index]->avg_frame_rate =
                input_format_context->streams[video_stream_index]->avg_frame_rate;

        out_codec_context->time_base.num *= input_codec_context->ticks_per_frame;
        out_codec_context->time_base.den *= 2;
        out_codec_context->ticks_per_frame = 2;

        out_codec_context->sample_aspect_ratio = input_codec_context->sample_aspect_ratio;

        av_dump_format(output_format_context, 0, output_name, 1);


* 打开输出视频文件


        if (!(output_format_context->flags & AVFMT_NOFILE)) {
                if (avio_open(&output_format_context->pb, output_name, AVIO_FLAG_WRITE) < 0) {
                        return -1;
                }
        }


* 输出视频文件头信息


        if (avformat_write_header(output_format_context, NULL) < 0) {
                return -1;
        }


* 获取每一帧的视频数据


        AVPacket avpkt;
        av_read_frame(input_format_context, &avpkt);
        av_free_packet(&avpkt); //记得每一帧数据使用完之后要释放，否则会有内存泄漏


* 输出一帧视频信息


        AVPacket opkt;
        av_init_packet(&opkt);
        opkt.data       = avpkt.data;
        opkt.size       = avpkt.size;

        if (avpkt.pts != AV_NOPTS_VALUE) {
                opkt.pts = av_rescale_q(avpkt.pts,
                                input_format_context->streams[video_stream_index]->time_base,
                                out_codec_context->time_base);
        } else {
                opkt.pts = AV_NOPTS_VALUE;
        }

        if (avpkt.dts == AV_NOPTS_VALUE) {
                opkt.dts = av_rescale_q(avpkt.dts,
                                AV_TIME_BASE_Q,
                                out_codec_context->time_base);
        } else {
                opkt.dts = av_rescale_q(avpkt.dts, 
                                input_format_context->streams[video_stream_index]->time_base,
                                out_codec_context->time_base);
        }

        opkt.duration = av_rescale_q(avpkt.duration, 
                        input_format_context->streams[video_stream_index]->time_base,
                        out_codec_context->time_base);
        opkt.flags = avpkt.flags;

        av_interleaved_write_frame(output_format_context, &opkt);
        out_codec_context->frame_number++;


* 写入完需要的信息或者输入多媒体播放完时，要写入文件尾并关闭文件


        av_write_trailer(output_format_context);
        avio_close(output_format_context->pb);
        
        
* 释放资源


        av_free(out_codec_context->extradata);
        avcodec_close(input_codec_context);
        avcodec_close(out_codec_context);
        avformat_close_input(&input_format_context);
        avformat_free_context(output_format_context);


## 小结

经以上步骤，即可以获取到基于rtsp的码流(h264祼码流),得到码流后即可以根据自己的需要来处理了。我这里只是将一个支持rtsp的IPCam码流收回来作录像处理，所以在收到码流后，直接写入到相应的视频文件即可。

(注：只作使用ffmpeg接口来获取rtsp码流记录）

