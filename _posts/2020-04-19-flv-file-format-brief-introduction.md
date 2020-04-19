---
title: FLV格式详解
date: 2020-04-19 22:28:00
category: Video
tags: Video, FLV
layout: post
---

## 一、FLV文件格式

FLV文件由 FLV header 和 FLV File Body 两部分组成，如下图所示

![FLV组成示意图](http://111.229.152.231/images/note/2020/flv_brief_description/flv_description.png)

### 1.1 FLV header 组成

| Field             | Type    | 说明                     |
|-------------------|---------|------------------------|
| Signature         | UI8     | 文件标识符，总是为F，即0x46       |
| Signature         | UI8     | 文件标识符，总是为L，即0x4C       |
| Signature         | UI8     | 文件标识符，总是为F，即0x56       |
| Version           | UI8     | 文件版本号，当前为1，即0x01       |
| TypeFlagsReserved | UB[5]   | 低5位为保留位，必须为0           |
| TypeFlagsAudio    | UB[1]   | 音频表示位，如为1，即存在音频        |
| TypeFlagsReserved | UB[1]   | 第7位是保留位，必须为0           |
| TypeFlagsVideo    | UB[1]   | 视频表示位，如为1，即存在视频        |
| DateOffset        | UI32    | header的长度，以字节计算；版本1总为9 |

### 1.2 FLV File Body 组成

FLV File Body 由多组 Tag 和 PreviousTagSize 组成， PreviousTagSize 表示前一个 Tag 的大小。

| Field               | Type   | 说明            |
|---------------------|--------|---------------|
| PreviousTagSize0    | UI32   | 表示0号Tag的大小，填0 |
| Tag1                | FLVTAG | 第一个Tag        |
| PreviousTagSize1    | UI32   | 第一个Tag的长度     |
| Tag2                | FLVTAG | 第二个Tag        |
| \.\.\.              |        |               |
| PreviousTagSizeN\-1 | UI32   | 第N\-1个Tag的长度  |
| TagN                | FLVTAG | 第N个Tag        |
| PreviousTagSizeN    | UI32   | 第N个Tag的长度     |

## 二、Tag 的组成

Tag 根据类型可分为 "Audio Tag"、"Video Data"、"Script Data" 三种不同的 Tag。

![FLV头和Tag组成示意图](http://111.229.152.231/images/note/2020/flv_brief_description/flv_construction.png)

Tag 由 Tag Header 和 Tag Data 组成，三种类型的 Tag 包所应的 Tag Header 组成相同，但 Tag Data 组成不同；下面分别对 Tag Header 和三种类型的 Tag Data 进行说明。

### 2.1 Tag Header 组成

| Field             | Type    | 说明                                          |
|-------------------|---------|---------------------------------------------|
| Reserved          | UB[2]   | 低两位是FMS保留位，必须为0                             |
| Filter            | UB[1]   | 是否需要解密标记，1为需要解密                             |
| TagType           | UB[5]   | Tag类型标记，0x08表示音频，0x09表示视频，0x12表示script data |
| DataSize          | UI24    | 从streamID至Tag尾的长度，即Tag包长度减去11               |
| Timestamp         | UI24    | 该tag相对于第一个tag的时间戳，第一个tag时间戳为0，单位是毫秒         |
| TimestampExtended | UI8     | 时间戳的扩展字节，如Timestamp不够用时，该字节补充高8位，组成一个32位数值  |
| StreamID          | UI24    | 总为0                                         |
| Tag Data          |         | 不同类型的Tag的Data部分结构各不相同，但Tag header的结构相同   |


Tag Data 分来 "Audio Tag Data"、"Video Tag Data"、"Script Tag Data" 三种不同的 Tag。

### 2.2 Audio Tag Data 组成

Audio Tag Data 由 AudioTagHeader 和 AudioData 两部分组成，其中 AudioTagHeader 为音频参数的描述信息（metadata）。AudioData 为音频数据，如果是加密数据，则此部分为编码后经加密处理的音频数据（见官方手册F.3.3说明）；否则就是编码后的音频数据。

* AudioTagHeader 组成

| Field         | Type    | 说明                                                            |
|---------------|---------|---------------------------------------------------------------|
| SoundFormat   | UB[4]   | 音频数据格式（其中格式7、8、14和15作为备用）                      |
|               |         | 0=Linear PCM, platform endian                                 |
|               |         | 1=ADPCM                                                       |
|               |         | 2=MP3                                                         |
|               |         | 3=LInear PCM, little endian                                   |
|               |         | 4=Nellymoser 16kHz mono                                       |
|               |         | 5=Nellymoser 8kHz mono                                        |
|               |         | 6=Nellymoser                                                  |
|               |         | 7=G\.711 A\-law logarithmic PCM                               |
|               |         | 8=G\.711 mu\-law logarithmic PCM                              |
|               |         | 9=reserved                                                    |
|               |         | 10=AAC                                                        |
|               |         | 11=speex                                                      |
|               |         | 14=MP3 8kHz                                                   |
|               |         | 15=Device\-specific sound                                     |
| SoundRate     | UB[2]   | 音频采集率；0=5\.5kHz，1=11kHz，2=22kHz，3=44kHz                |
| SoundSize     | UB[1]   | 音频数据采集精度：0=8位采样、1=16位采样                          |
| SoundType     | UB[1]   | 音频类型：0=Mono sound，1=Stereo sound                         |
| AACPacketType | UI8     | 如果SoundFormat值为10时，存在；AAC打包类型：0=AAC sequence header，1=AAC raw |
| SoundData     |         | 音频数据 |

* 如果使用了加密数据，就需要先解密。
* 如果 SoundFormatw值为10时，AACPacketType 值为0时， 后续的AAC音频数据为 AudioSpecificConfig 格式；如为1时，则为AAC RAW Frame 的UI8数组数据

根据 AudioSpecificConfig 结构的定义如下：

| Field                  | 类别       | 说明                                                        |
|------------------------|----------|-----------------------------------------------------------|
| audioObjectType        | UB[5]  | 取高5位，如值小于31，即为object type；如值为31，取高6位，并加上32的结果为object type |
| samplingFrequencyIndex | UB[4]  | 取低4位，如值小于15，即为frequencyIndex；如值为15，取低24位，则为特定的采样频率值       |
| channelConfiguration   | UB[4]  | 取第4\-7位                                                   |
| frameLengthFlag        | UB[1]  | 取第3位                                                      |
| dependsOnCoreCoder     | UB[1]  | 取第2个位                                                     |
| extensionFlag          | UB[1]  | 取第1位                                                      |

ffmpeg 中有对 AudioSpecificConfig 解析的函数 ff_mpeg4audio_get_config()，可参看和对比。

### 2.3 Video Tag Data 组成

Video Tag Data 由 VideoTagHeader 和 VideoData 两部分组成，其中 VideoTagHeader 为视频参数的描述信息（metadata）。VideoData 为视频数据，如果是加密数据，则此部分为编码后经加密处理的视频数据（见官方手册F.3.3说明）；否则就是编码后的视频数据。

* VideoTagHeader 组成

| Field           | Type             | 说明                                                                                  |
|-----------------|------------------|-------------------------------------------------------------------------------------|
| Frame Type      | UB[4]            | 视频帧类型                                                                               |
|                 |                  | 1=key frame（for AVC, a seekable frame）                                              |
|                 |                  | 2=inter frame（for AVC, a non\-seekable frame）                                       |
|                 |                  | 3=disposable inter frame（H\.263 only）                                               |
|                 |                  | 4=generated key frame（reserved for server use only）                                 |
|                 |                  | 5=video info/command frame                                                          |
| CodecID         | UB[4]            | 编码器类型                                                                               |
|                 |                  | 1=JPEG(currently unused)                                                                   |
|                 |                  | 2=Sorenson H\.263                                                                   |
|                 |                  | 3=Screen video                                                                      |
|                 |                  | 4=On2 VP6                                                                           |
|                 |                  | 5=On2 VP6 with alpha channel                                                        |
|                 |                  | 6=Screen video version 2                                                            |
|                 |                  | 7=AVC                                                                               |
| AVCPacketType   | 如果CodecID为7，UI8  | AVCPacketType取值如下                                                                   |
|                 |                  | 0=AVC sequence header（AVC序列头）                                                       |
|                 |                  | 1=AVC NALU                                                                          |
|                 |                  | 2=AVC end of sequence（lower level NALU sequence ender is not required or supported） |
| CompositionTime | 如果CodecID为7，SI24 | 如果AVCPacketType值为1时，表示时间的偏移量；其他为0                                                   |

* 如果使用了加密数据，就需要先解密。
* VideoTagBody：
  * 如果 FrameType 值为 5，则为视频帧信息或命令信息
  * 其他 FrameType 时，根据不同的 CodecID ，后续为相应的视频帧数据；如果 CodecID 值为7，则后续的视频帧数据为 AVCVIDEOPACKET
  * AVCVIDEOPACKET：如果 AVCPacketType 值为0，视频数据内容为 AVCDecoderConfigurationRecord（详细说明见ISO-14496-15 AVC file format， 5.2.4.1）；值为1，视频数据内容为一个或多个NALU

* AVCDecoderConfigurationRecord 的说明

| Field                        | 类别       | 说明                                                |
|------------------------------|----------|---------------------------------------------------|
| configurationVersion         | UI8      | configurationVersion，固定为 01                       |
| AVCProfileIndication         | UI8      | Profile code in ISO/IEC 14496\-10                 |
| profile\_compatibility       | UI8      |                                                   |
| AVCLevelIndication           | UI8      | level code in ISO/IEC 14496\-10                   |
| lengthSizeMinusOne           | UI8      | AVC编码是的NALU的长度，计算方法： 1 +(lengthSizeMinusOne & 3) |
| numOfSequenceParameterSets   | UI8      | SPS的个数，计算方法： numOfSequenceParameterSets & 0x1F     |
| sequenceParameterSetLength   | UI16     | SPS的长度                                            |
| sequenceParameterSetNALUnits | UI8[n] | SPS数据                                             |
| \.\.\.                       |          | 如果有多个SPS，重复上面的格式                                  |
| numOfPictureParameterSets    | UI8      | PPS的个数                                            |
| pictureParameterSetLength    | UI8      | PPS的长度                                            |
| pictureParameterSetNALUnits  | UI8[n] | PPS数据                                             |
| \.\.\.                       |          | 如果有多个PPS，重复上面的格式                                  |


### 2.4 Script Data 组成

Script Data 为控制帧，又通常被称为 MetaData Tag，会存放一些关于FLV视频和音频的元数据信息，如duration、width、height等。通过该类型Tag会跟在FLV header 后面，作为第一个Tag出现，而且只有一个。采用 AMF 方式进行编码。

* 如果使用了加密数据，就需要先解密。
* ScriptTagBody 由多个 Name 和 Value 对组成，Name 为命令或对象的名称，Value为命令参数或对象属性；Name 和 Value 均为SCRIPTDATAVALUE 格式
* SCRIPTDATAVALUE包含一个字节的数据类型和后面紧跟着的特定类型的数据实体，Type的定义如下

| Field | Type | 说明                                          |
|-------|------|---------------------------------------------|
| Type  | UI8  | ScriptDataValue                             |
|       |      | 0=Number，后面的数据是Double型                      |
|       |      | 1=Boolean                                   |
|       |      | 2=String，后面的数据是SCRIPTDATASTRING             |
|       |      | 3=Object，后面的数据是SCRIPTDATAOBJECT             |
|       |      | 4=MovieClip（reserved, not supported）        |
|       |      | 5=null                                      |
|       |      | 6=Undefined                                 |
|       |      | 7=Reference，后面的数据是UI16                      |
|       |      | 8=ECMA array，后面的数据是SCRIPTDATAECMAARRAY      |
|       |      | 9=Object end marker                         |
|       |      | 10=String array，后面的数据是SCRIPTDATASTRICTARRAY |
|       |      | 11=Date，后面的数据是SCRIPTDATADATE                |
|       |      | 12=Long string，后面的数据是SCRIPTDATALONGSTRING   |

* FLV metadata 对象以 onMetadata 名称的对象出来在第一个 Script Data tag 中
  * 第1个字节表示AMF包类型，一般总是0x02，表示字符串
  * 第2-3字节为UI16类型值，表示字符串的长度，一般总是0x000A（"onMetaData"长度）
  * 后面的字节为具体的字符串内容，一般总为 "onMetaData" （6F,6E,4D,65,74,61,44,61,74,61）
* FLV metadata 对象的值，在第二个AMF包中体现
  * 第1个字节表示AMF包类型，一般总是0x08，表示数组
  * 第2-5个字节为UI32类型值，表示数组元素的个数
  * 后面即为各数据元素的封装，数组元素为元素名称和值组成的对


以下以width=720的情况简要说明 metadata 的组成，见下面的示意图：

![FLV Scriptdata metadata示意图](http://111.229.152.231/images/note/2020/flv_brief_description/flv_scriptdata_metadata.png)


常见的数据元素如下表所示：

| Field           | Type    | 说明           |
|-----------------|---------|--------------|
| audiocodecid    | Number  | 音频编码方式       |
| audiodatarate   | Number  | 音频码率         |
| audiodelay      | Number  | 音频的延时（单位：秒）  |
| audiosamplerate | Number  | 音频采样率        |
| audiosamplesize | Number  | 音频采样精度       |
| canSeekToEnd    | Boolean | 是否可定位到最后的关键帧 |
| creationdate    | String  | 创建日期和时间      |
| duration        | Number  | 时长           |
| filesize        | Number  | 文件大小         |
| framerate       | Number  | 视频帧率         |
| height          | Number  | 视频高度         |
| stereo          | Boolean | 是否为立体声       |
| videocodecid    | Number  | 视频编码方式       |
| videodatarate   | Number  | 视频码率         |
| width           | Number  | 视频宽度         |

### 2.5 SCRIPTDATAVAVLUE 不同数据类型的说明

SCRIPTDATAVALUE可分为 8 种不同的数据类型，每个数据类型的说明如下所示：

* SCRIPTDATADATE 类型

| Field               | Type   | 说明                                                |
|---------------------|--------|---------------------------------------------------|
| DateTime            | Double | Number of milliseconds since Jan 1, 1970 UTC\.    |
| LocalDateTimeOffset | SI16   | Local time offset in minutes from UTC，东时区为正，西时区为负 |

* SCRIPTDATAECMAARRAY 类型

| Field           | Type                          | 说明                                |
|-----------------|-------------------------------|-----------------------------------|
| ECMAArrayLength | UI32                          | ECMA数组元素的数量                         |
| Variables       | SCRIPTDATAOBJECTPROPERTY[ ] | List of variable names and values |
| List Terminator | SCRIPTDATAOBJECTEND           | List terminator                   |

* SCRIPTDATALONGSTRING 类型

| Field        | Type   | 说明                  |
|--------------|--------|---------------------|
| StringLength | UI32   | StringData长度（多少个字节） |
| StringData   | String | String数据，没有NULL结束符  |

* SCRIPTDATAOBJECT 类型

| Field            | Type                          | 说明                        |
|------------------|-------------------------------|---------------------------|
| ObjectProperties | SCRIPTDATAOBJECTPROPERTY[ ] | List of object properties |
| List Terminator  | SCRIPTDATAOBJECTEND           | List结束符                   |

* SCRIPTDATAOBJECTEND 类型

| Field           | Type     | 说明       |
|-----------------|----------|----------|
| ObjectEndMarker | UI8[3] | 必须是0,0,9 |

* SCRIPTDATAOBJECTPROPERTY 类型

| Field        | Type             | 说明         |
|--------------|------------------|------------|
| PropertyName | SCRIPTDATASTRING | 对象属性或变量的名称 |
| PropertyData | SCRIPTDATAVALUE  | 对象或变量的值    |

* SCRIPTDATASTRICTARRAY 类型

| Field             | Type                                 | 说明    |
|-------------------|--------------------------------------|-------|
| StringArrayLength | UI32                                 | 数组的长度 |
| StringArrayValue  | SCRIPTDATAVALUE[StrictArrayLength] | 数值    |

* SCRIPTDATASTRING 类型

| Field        | Type   | 说明                        |
|--------------|--------|---------------------------|
| StringLength | UI16   | 字符串的长度                    |
| StringData   | String | 字符串，最大长度65535字节，不含NULL结束符 |

## 三、参考
1. [F4V/FLV Technology Center](https://www.adobe.com/devnet/f4v.html)
2. [视音频编解码学习工程：FLV封装格式分析器](https://blog.csdn.net/leixiaohua1020/article/details/17934487)
3. [直播协议 HTTP-FLV 详解](https://segmentfault.com/a/1190000010791731)
4. [FLV格式详解](https://blog.csdn.net/weixin_42462202/article/details/88661883)
5. [MPEG-4 Audio](https://wiki.multimedia.cx/index.php?title=MPEG-4_Audio)
6. [flv文件AVCDecoderConfigurationRecord以及AudioSpecificConfig结构](https://blog.csdn.net/jwybobo2007/article/details/9221657)

