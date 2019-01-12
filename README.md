# Live Stream Recorder

一系列简陋的 Bash 脚本，可以实现 YouTube、OPENREC、Twitch、TwitCasting 等平台主播开播时自动录像。

因为我喜欢的 VTuber [神楽めあ](https://twitter.com/freeze_mea) 是个喜欢突击直播还不留档的惯犯，所以我写了这些脚本挂在 VPS 上监视直播动态，一开播就自动开始录像，这样就算错过了直播也不用担心。

脚本的工作原理很简单，就是每隔一段时间检查一次直播状态（这个延迟可以通过脚本调用参数调节），如果在播就开始录像，没在播就继续轮询，非常简单粗暴（因为我懒得用 PubSubHubbub，而且我这台 VPS 就是专门为了录像买的，所以不用在意性能之类的问题）。

这些脚本支持的直播平台基本上覆盖了 mea 的活动范围，如果有其他希望支持的平台也可以开 issue。

## 前置依赖

本脚本依赖以下程序，请自行安装并保证能在 `$PATH` 中找到。

- ffmpeg
- youtube-dl
- streamlink

需要注意的是，各大 Linux 发行版官方软件源中的 ffmpeg 版本可能过旧（3.x 甚至 2.x），录像时会出现奇怪的问题，推荐在 [这里](https://johnvansickle.com/ffmpeg/) 下载最新版本（4.x）的预编译二进制文件。

youtube-dl 和 streamlink 都可以直接使用 pip 进行安装。

## YouTube 自动录像

```bash
./record_youtube.sh url [format] [loop|once] [interval]

# Example
./record_youtube.sh "UCWCc8tO-uUl_7SJXIKJACMw"
./record_youtube.sh "https://www.youtube.com/channel/UCWCc8tO-uUl_7SJXIKJACMw/live" best loop 30
./record_youtube.sh "https://www.youtube.com/watch?v=NeQrejV3JnE" best once
./record_youtube.sh "https://youtu.be/WMu7SGeUTG4" 480p
```

第一个参数为 YouTube 频道 ID（就是频道 URL `youtube.com/channel` 后面的那个），或者待机室的 URL（即在频道 URL 后面添加 `/live`），这样可以实现无人值守监视开播。参数也可以是某次直播的直播页面 URL（如示例三），不过这样就只能对这一场直播进行录像，录不到该频道的后续直播，所以推荐使用前者。

第二个参数为可选参数，指定录像的画质，默认为可用的最高画质。更多可以使用的格式字符串请参考 [streamlink `STREAM` 参数的文档](https://streamlink.github.io/cli.html#cmdoption-arg-stream)。e.g. 指定为 `720p,480p,best` 即可以最高不大于 720p 的格式录像。

第三个参数为可选参数，如果指定为 `once`，那么当前直播的录像完成后脚本会自动退出，而不会继续监视后续直播。

第四个参数为每次直播流状态检查之间的间隔（单位为秒，默认值为 `10`，即每隔 10s 检查一次）。

录像文件默认保存在脚本文件所在的目录下，文件名格式为 `youtube_{id}_YYMMDD_HHMMSS.ts`。输出的视频文件使用 MPEG-2 TS 容器格式保存，因为 TS 格式有着可以从任意位置开始解码的优势，就算录像过程中因为网络波动等问题造成了中断，也不至于损坏整个视频文件。如果需要转换为 MP4 格式，可以使用以下命令：

```bash
ffmpeg -i xxx.ts -codec copy xxx.mp4
```

为了避免下播后 ffmpeg 录像进程依然挂起（因为我没做输入流的可用性判断，所以以前的脚本会有进程挂起的问题，可能造成挂起期间内无法录像等问题），以及支持 HLS Seeking（即从中途开始运行也能从当前直播的开头处开始录像，不过只在有限的情况下可用），本脚本使用 streamlink 而非 ffmpeg 进行录像。另外，当前直播的元信息（ID、标题、概要栏等）保存在 `视频文件名.info.txt` 文件中，录像时 streamlink 进程的详细输出会写入至 `视频文件名.log` 日志文件，使用 `tail -f xxx.log` 命令可以实时查看。

## OPENREC 自动录像

```bash
./record_openrec.sh openrec_id [format] [loop|once] [interval]

# Example
./record_openrec.sh KaguraMea 480p
./record_openrec.sh 23_kanae best once
```

此脚本依赖 curl 以从用户频道页面获取当前的直播信息。

第一个参数为 OPENREC 用户名，就是用户主页 URL 中 `openrec.tv/user` 后面的那个。第二、三、四个参数与 YouTube 的脚本相同。

录像的文件名格式为 `openrec_{id}_YYMMDD_HHMMSS.ts`，其他与上面的相同。

另外，streamlink v0.14.2 对 OPENREC 的支持有问题，你需要参照这个 [issue](https://github.com/streamlink/streamlink/issues/1960#issuecomment-408809306) 手动加载更新后的 streamlink OPENREC 插件，或者等待 streamlink 本体发布新版本。如果运行中出现了 `error: 'ascii' codec can't encode character` 错误，那么你可能需要升级 Python 2.x 至 Python 3.x，或者在 `streamlink/plugins/openrectv.py` 文件的头部添加以下代码：

```python
import sys
reload(sys)
sys.setdefaultencoding('utf8')
```

## Twitch 自动录像

```bash
./record_twitch.sh twitch_id [format] [loop|once] [interval]

# Example
./record_twitch.sh kagura0mea 480p
./record_twitch.sh wuyikoei best once
```

第一个参数为 Twitch 用户名，就是直播页面 URL 中 `twitch.tv` 后面的那个。第二、三、四个参数与 YouTube 的脚本相同。

录像的文件名格式为 `twitch_{id}_YYMMDD_HHMMSS.ts`，其他与上面的相同。

## TwitCasting 自动录像

```bash
./record_twitcast.sh twitcasting_id [loop|once] [interval]

# Example
./record_twitcast.sh kaguramea
./record_twitcast.sh twitcasting_jp once
```

第一个参数为 TwitCasting 用户名，就是直播页面 URL 中 `twitcasting.tv` 后面的那个。第二个参数为可选参数，如果指定为 `once`，那么当前直播的录像完成后脚本会自动退出，而不会继续监视后续直播。此脚本无法指定要抓取的直播流的画质。

录像的文件名格式为 `twitcast_{id}_YYMMDD_HHMMSS.ts`（画质较差），其他与上面的相同。

另外，由于 TwitCasting 的高清录像必须通过 WebSocket 获取，而且 bash 脚本在这方面比较力不从心，所以推荐配合 [livedl](https://github.com/himananiito/livedl) 这个工具来实现 TwitCasting 平台的高清录像。将构建好的 livedl 可执行文件放在与此脚本相同的目录下即可，脚本会自动调用（由于上游限制，高清录像的文件名格式固定为 `{twitcasting_id}_{movie_id}.ts`）。

## 其他直播平台自动录像

基本上 [streamlink 支持的直播站点](https://streamlink.github.io/plugin_matrix.html) 都支持（包括国内的斗鱼、熊猫什么的）。

```bash
./record_streamlink.sh live_url [format] [loop|once] [interval]

# Example
./record_streamlink.sh "https://www.douyu.com/3614"
./record_streamlink.sh "https://www.panda.tv/371037"
```

第一个参数为直播间 URL，第二、三、四个参数与 YouTube 的脚本相同。

录像的文件名格式为 `stream_YYMMDD_HHMMSS.ts`，其他与上面的相同。

## 通过 `.m3u8` 地址手动录像

此脚本适用于任何已知 `.m3u8` 地址的情况，不过只能对传入的该场直播进行录像，无法监视后续直播与自动录像。

如果上面的脚本没有适配某个平台（比如 Mirrativ、SHOWROOM），你也可以自己抓取出 `.m3u8` 地址手动开始录像。

```bash
./record_m3u8.sh "https://record.mirrativ.com/archive/hls/39/0018438274/playlist.m3u8"
```

第一个参数为 `.m3u8` 地址，录像的文件名格式为 `stream_YYMMDD_HHMMSS.ts`。

第二个参数为可选参数，指定为 `loop` 可以让脚本每隔一段时间（第三个参数）尝试下载该 `.m3u8` 地址。

## 转播推流

这些脚本虽然是用来录像的，但是稍微修改一下也可以用于推流转播至其他直播平台。

将各脚本中的：

```bash
ffmpeg -i "$M3U8_URL" -codec copy -f mpegts "$FNAME" > "$FNAME.log" 2>&1
```

修改为：

```bash
RTMP_URL="这里填你的 RTMP 推流地址"
ffmpeg -i "$M3U8_URL" \
  -codec copy -f mpegts "$FNAME" \ # 不需要录像的可以去掉这一行
  -vcodec copy -acodec aac -strict -2 -f flv "$RTMP_URL" \
  > "$FNAME.log" 2>&1
```

即可实现同时录像与转播推流。

## 后台运行脚本

如果用上面那些方式运行脚本，终端退出后脚本就会停止，所以你需要使用 `nohup` 命令将脚本放到后台中运行：

```bash
nohup ./record_youtube.sh "UCWCc8tO-uUl_7SJXIKJACMw" > mea.log &
```

这会把脚本的输出写入至日志文件 `mea.log`（文件名自己修改），你可以随时使用 `tail -f mea.log` 命令查看实时日志。

其他脚本同理：

```bash
nohup ./record_twitch.sh kagura0mea > mea_twitch.log &
nohup ./record_twitcast.sh kaguramea > mea_twitcast.log &
nohup ./record_openrec.sh KaguraMea > mea_openrec.log &
```

使用命令 `ps -ef | grep record` 可以列出当前正在后台运行的录像脚本，其中第一个数字即为脚本进程的 PID：

```text
root      1166     1  0 13:21 ?        00:00:00 /bin/bash ./record_youtube.sh ...
root      1558     1  0 13:25 ?        00:00:00 /bin/bash ./record_twitcast.sh ...
root      1751     1  0 13:27 ?        00:00:00 /bin/bash ./record_twitch.sh ...
root      1755     1  0 13:29 ?        00:00:00 /bin/bash ./record_openrec.sh ...
```

如果需要终止正在后台运行的脚本，可以使用命令 `kill {pid}`（比如要终止上面的第一个 YouTube 录像脚本，运行 `kill 1166` 即可）。

## 开源许可

MIT License (c) 2018 printempw
