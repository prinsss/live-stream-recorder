#!/bin/bash
# Automatic TwitCasting Streaming Recorder
# echo -ne "\033]0;[REC] TwitCasting $1\007"

if [ -n "$1" ]; then
  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="twitcast_${1}_$(date +"%Y%m%d_%H%M%S").ts"
  CMD="ffmpeg -i http://twitcasting.tv/$1/metastream.m3u8?video=1 -codec copy -f mpegts $FNAME"

  while true; do
    $CMD
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after 30 seconds..."
    sleep 30
  done

else
  echo "usage: $0 twitcasting_id"
fi
