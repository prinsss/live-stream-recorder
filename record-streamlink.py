#!/usr/bin/python
import os,time,sys
import streamlink
import subprocess

'''
'
' Auto live recorder python version
'
' need those program below, please installl and besure in PATH
'
' ffmpeg
' streamlink
'
' support for Python 3+
'
' test pass with Douyu.tv/90080
'
'''

# StreamUrl full support website list: https://streamlink.github.io/plugin_matrix.html
# e.g. URL = 'https://www.douyu.com/90080'
# 直播地址变量，支持列表请看这里：https://streamlink.github.io/plugin_matrix.html
# 示例：URL = 'https://www.douyu.com/90080'

URL = None

# video quality，support worst,480p,720p,best
# 录播质量

Quality = "best"

# auto cut by time (second), have some runtime dely, may not accuracy.
# 自动分P，时长模式（秒），有些许程序运行误差。
CutTime = 60 * 60 * 1

# record once or loop
# 录制一次直播还是无人监管模式
RecTimes = "loop"

# Live Stream Recorder Start
if URL == None :
    print('请修改本文件中开始的固定变量来存储录像地址')
    print('please change the var URL at top to define the stream URL')
    time.sleep(3)
    sys.exit()

while True :
    # Create log file
    Log_Date = time.strftime("%Y-%m-%d %H-%M-%S", time.localtime())
    
    # Monitor live streams of specific channel
    while True :

        try :
            # Get the M3U8 Dict address with streamlink
            M3U8_Dict = streamlink.streams(URL)
            # Get the specific quality use variable Quality
            M3U8_Key = M3U8_Dict[Quality]
            M3U8_Url = M3U8_Key.url
            break
        except :
            print('Monitor live stream now, current not live, please wait...')
            print('Retry after 5 seconds...')
        time.sleep(5)
    # Record using MPEG-2 TS format to avoid broken file caused by interruption
    Filename = 'record-' + Log_Date + '.ts'
    # Start recording
    FFmpeg_Cmd = 'ffmpeg -i "' + M3U8_Url + '" -codec copy -f mpegts "' + Filename + '"'
    Recording_Stream = subprocess.Popen(FFmpeg_Cmd)
    time.sleep(1)

    # Auto cut by time
    Timer = 0
    while True :
        if (Recording_Stream.poll() == None) and (Timer < CutTime) :
            Timer += 1
            time.sleep(1)
        elif Timer >= CutTime :
            Recording_Stream.kill()
            break
        else :
            Recording_Stream.kill()
            break
    # Exit if we just need to record current stream
    if RecTimes == "once" : break
