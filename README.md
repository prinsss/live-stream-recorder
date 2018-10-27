# Live Stream Recorder

一系列简陋的 Bash 脚本，可以实现 YouTube、OPENREC、Twitch、TwitCasting 等平台主播开播时自动录像。

因为我喜欢的 VTuber [神楽めあ](https://twitter.com/freeze_mea) 是个喜欢突击直播还不留档的惯犯，所以我写了这些脚本挂在 VPS 上监视直播动态，一开播就自动开始录像，这样就算错过了直播也不用担心。

脚本的工作原理很简单，就是每过 30s 检查一次直播状态（这个延迟可以在脚本中的 `sleep 30` 处调节），如果在播就开始录像，没在播就继续轮询，非常简单粗暴（因为我懒得用 PubSubHubbub，而且我这台 VPS 就是专门为了录 mea 买的，所以不用在意性能之类的问题）。

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
./record_youtube.sh url [format] [loop|once]

# Example
./record_youtube.sh "https://www.youtube.com/channel/UCWCc8tO-uUl_7SJXIKJACMw/live"
./record_youtube.sh "https://www.youtube.com/watch?v=NeQrejV3JnE" best once
./record_youtube.sh "https://youtu.be/WMu7SGeUTG4" "bestvideo[height<=480]+bestaudio"
```

第一个参数为 YouTube 频道待机室的 URL（即在频道 URL 后面添加 `/live`），这样可以实现无人值守监视开播。参数也可以是某次直播的直播页面 URL（如示例二），不过这样就只能对这一场直播进行录像，录不到该频道的后续直播，所以推荐使用前者。如果频道主关闭了非直播时间的 `/live` 待机室也没关系，脚本也对此情况进行了适配。

第二个参数为可选参数，指定录像的画质，不指定的话默认以最高不大于 720p 的格式录像（即 `best[height<=720]`）。指定为 `best` 即可使用可用的最高画质进行录像（注意机器硬盘空间），更多可以使用的格式字符串请参考 [youtube-dl `-f` 参数的文档](https://github.com/rg3/youtube-dl#format-selection)。

第三个参数为可选参数，如果指定为 `once`，那么当前直播的录像完成后脚本会自动退出，而不会继续监视后续直播。

录像文件默认保存在脚本文件所在的目录下，文件名格式为 `youtube_{id}_YYMMDD_HHMMSS.ts`。输出的视频文件使用 MPEG-2 TS 容器格式保存，因为 TS 格式有着可以从任意位置开始解码的优势，就算录像过程中因为网络波动等问题造成了中断，也不至于损坏整个视频文件。如果需要转换为 MP4 格式，可以使用以下命令：

```bash
ffmpeg -i xxx.ts -codec copy xxx.mp4
```

另外，当前直播的元信息（包括标题、概要栏等）保存在 `视频文件名.info.json` 文件中，录像时 ffmpeg 进程的详细输出会写入至 `视频文件名.log` 日志文件，使用 `tail -f xxx.log` 命令可以实时查看。

## OPENREC 自动录像

```bash
./record_openrec.sh openrec_id [format] [loop|once]

# Example
./record_openrec.sh KaguraMea 480p
./record_openrec.sh 23_kanae best once
```

此脚本依赖 curl 以从用户频道页面获取当前的直播信息。

第一个参数为 OPENREC 用户名，就是用户主页 URL 中 `openrec.tv/user` 后面的那个。

第二个参数为可选参数，指定录像的画质，不指定的话默认以最高不大于 720p 的格式录像（即 `720p,480p,best`）。指定为 `best` 即可使用可用的最高画质进行录像（注意机器硬盘空间），更多可以使用的格式字符串请参考 [streamlink `STREAM` 参数的文档](https://streamlink.github.io/cli.html#cmdoption-arg-stream)。

第三个参数为可选参数，如果指定为 `once`，那么当前直播的录像完成后脚本会自动退出，而不会继续监视后续直播。

录像的文件名格式为 `openrec_{id}_YYMMDD_HHMMSS.ts`，其他与上面的相同。

另外，streamlink v0.14.2 对 OPENREC 的支持有问题，你需要参照这个 [issue](https://github.com/streamlink/streamlink/issues/1960#issuecomment-408809306) 手动加载更新后的 streamlink OPENREC 插件，或者等待 streamlink 本体发布新版本。如果运行中出现了 `error: 'ascii' codec can't encode character` 错误，那么你可能需要升级 Python 2.x 至 Python 3.x，或者在 `streamlink/plugins/openrectv.py` 文件的头部添加以下代码：

```python
import sys
reload(sys)
sys.setdefaultencoding('utf8')
```

## Twitch 自动录像

```bash
./record_twitch.sh twitch_id [format] [loop|once]

# Example
./record_twitch.sh kagura0mea 480p
./record_twitch.sh wuyikoei best once
```

第一个参数为 Twitch 用户名，就是直播页面 URL 中 `twitch.tv` 后面的那个。第二、第三个参数与 OPENREC 的脚本相同。

录像的文件名格式为 `twitch_{id}_YYMMDD_HHMMSS.ts`，其他与上面的相同。

## TwitCasting 自动录像

```bash
./record_twitcast.sh twitcasting_id [loop|once]

# Example
./record_twitcast.sh kaguramea
./record_twitcast.sh twitcasting_jp once
```

第一个参数为 TwitCasting 用户名，就是直播页面 URL 中 `twitcasting.tv` 后面的那个。第二个参数为可选参数，如果指定为 `once`，那么当前直播的录像完成后脚本会自动退出，而不会继续监视后续直播。此脚本无法指定要抓取的直播流的画质。

录像的文件名格式为 `twitcast_{id}_YYMMDD_HHMMSS.ts`，其他与上面的相同。

## 通过 `.m3u8` 地址手动录像

此脚本适用于任何已知 `.m3u8` 地址的情况，不过只能对传入的该场直播进行录像，无法监视后续直播与自动录像。

如果上面的脚本没有适配某个平台（比如 Mirrativ、SHOWROOM），你也可以自己抓取出 `.m3u8` 地址手动开始录像。

```bash
./record_m3u8.sh https://record.mirrativ.com/archive/hls/39/0018438274/playlist.m3u8
```

第一个参数为 `.m3u8` 地址，录像的文件名格式为 `stream_{id}_YYMMDD_HHMMSS.ts`。

第二个参数为可选参数，指定为 `loop` 可以让脚本每隔 30s 尝试下载该 `.m3u8` 地址。

## 后台运行脚本

如果用上面那些方式运行脚本，终端退出后脚本就会停止，所以你需要使用 `nohup` 命令将脚本放到后台中运行：

```bash
nohup ./record_youtube.sh "https://www.youtube.com/channel/UCWCc8tO-uUl_7SJXIKJACMw/live" > mea.log &
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
```

如果需要终止正在后台运行的脚本，可以使用命令 `kill {pid}`（比如要终止上面的第一个 YouTube 录像脚本，运行 `kill 1166` 即可）。

## 已知问题

YouTube 录像脚本中，youtube-dl 调起的 ffmpeg 进程有时候在直播结束后还会继续运行，一直持续很长时间才自动退出（几十分钟到几小时不等，表现为日志文件中不断出现的 `Last message repeated xxx times`），原因不明，似乎是 youtube-dl 的一个 [BUG](https://github.com/rg3/youtube-dl/issues/12271)。如果 ffmpeg 进程一直不退出就会造成阻塞，导致在这段时间内新开的直播无法录像，所以推荐在看到 YouTube 下播后手动终止一下可能挂起的 ffmpeg 进程。

首先运行 `ps -ef | grep youtube-dl` 获取 `youtube-dl` 进程的 PID：

```text
root     26614  1166 29 20:31 ?        00:00:00 /usr/bin/python /usr/local/bin/youtube-dl --no-playlist --playlist-items 1 --match-filter is_live --hls-use-mpegts -o youtube_%(id)s_20181021_203125_%(title)s.ts https://www.youtube.com/channel/UCWCc8tO-uUl_7SJXIKJACMw/live
```

然后使用以下命令向 youtube-dl 进程发送 `SIGINT` 信号终止程序：

```bash
kill -s INT 26614
```

为什么是向 youtube-dl 而非 ffmpeg 进程发送信号？因为 youtube-dl 在 ffmpeg 进程正常退出之后还需要进行一些操作（比如对 `.part` 文件进行处理），而如果直接向 ffmpeg 进程发送 `SIGINT` 信号会让 youtube-dl 以为 ffmpeg 进程异常退出（而非接受用户的中断指令退出），就不会进行那些后续处理。发送 `SIGINT` 信号而非其他信号也是为了让它可以执行这些操作。

如果是其他平台的录像脚本，那直接向 ffmpeg 进程发送 `SIGINT` 信号就可以了。

## 开源许可

MIT License (c) 2018 printempw
