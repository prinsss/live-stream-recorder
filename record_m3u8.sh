#!/bin/bash
# General m3u8 Live Stream Recorder

if [ ! -n "$1" ]; then
  echo "usage: $0 m3u8_url [loop]"
  exit 1
fi

while true; do
  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="stream_$(date +"%Y%m%d_%H%M%S").ts"
  ffmpeg -i "$1" -codec copy -f mpegts "$FNAME"

  [ "$2" != "loop" ] && break

  LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
  echo "$LOG_PREFIX The stream is not available now."
  echo "$LOG_PREFIX Retry after 30 seconds..."
  sleep 30
done
