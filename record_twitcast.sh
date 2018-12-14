#!/bin/bash
# TwitCasting Live Stream Recorder

if [[ ! -n "$1" ]]; then
  echo "usage: $0 twitcasting_id [loop|once]"
  exit 1
fi

# Specify "video=1" to get video & audio stream
M3U8_URL="http://twitcasting.tv/$1/metastream.m3u8?video=1"

while true; do
  # Monitor live streams of specific user
  while true; do
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX Try to get current live stream of twitcasting.tv/$1"
    (curl -s "$M3U8_URL" | grep -q "#EXTM3U") && break

    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after 30 seconds..."
    sleep 30
  done

  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="twitcast_${1}_$(date +"%Y%m%d_%H%M%S").ts"
  echo "$LOG_PREFIX Start recording, stream saved to \"$FNAME\"."
  echo "$LOG_PREFIX Use command \"tail -f $FNAME.log\" to track recording progress."

  # Record high resolution stream using livedl
  # Build livedl from https://github.com/himananiito/livedl and
  # put the binary file to the same directory of this script to enable.
  if [[ -f "./livedl" ]]; then
    ./livedl -tcas "$1" > "$FNAME.livedl.log" 2>&1 &
    echo "$LOG_PREFIX Start recording high resolution stream simultaneously with livedl."
  fi

  # Start recording
  ffmpeg -i "$M3U8_URL" -codec copy -f mpegts "$FNAME" > "$FNAME.log" 2>&1

  # Exit if we just need to record current stream
  LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
  echo "$LOG_PREFIX Live stream recording stopped."
  [[ "$2" == "once" ]] && break
done
