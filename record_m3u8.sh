#!/bin/bash
# General m3u8 Live Stream Recorder
# echo -ne "\033]0;[REC] $1\007"

if [ -n "$1" ]; then
  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="stream_$(date +"%Y%m%d_%H%M%S").ts"
  CMD="ffmpeg -i $1 -codec copy -f mpegts $FNAME"

  while true; do
    $CMD
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after 30 seconds..."
    sleep 30
  done

else
  echo "usage: $0 m3u8_url"
fi
