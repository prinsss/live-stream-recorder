#!/bin/bash
# Automatic YouTube Streaming Recorder
# echo -ne "\033]0;[REC] $1\007"

if [ -n "$1" ]; then
  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="youtube_%(id)s_$(date +"%Y%m%d_%H%M%S")_%(title)s.ts"
  # Adapt for passing channel URL directly or the taiki-heya is closed
  CMD="youtube-dl --no-playlist --playlist-items 1 --match-filter is_live \
    --hls-use-mpegts -o $FNAME $1"

  while true; do
    $CMD
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after 30 seconds..."
    sleep 30
  done

else
  echo "usage: $0 youtube_live_page"
fi
