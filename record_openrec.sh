#!/bin/bash
# Automatic OPENREC.tv Streaming Recorder
# echo -ne "\033]0;[REC] OPENREC $1\007"

if [ -n "$1" ]; then

  while true; do
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")

    # Extract current live stream from channel page
    echo "$LOG_PREFIX Try to get current live stream from openrec.tv/user/$1"

    LIVE_URL=$(curl -s "https://www.openrec.tv/user/$1" |\
      grep -Eoi "href=\"https://www.openrec.tv/live/(.+)\" class" |\
      head -n 1 | cut -c "7-" | cut -d "\"" -f 1)

    if [ ! -z "$LIVE_URL" ]; then
      # Record using MPEG-2 TS format to avoid broken file caused by interruption
      FNAME="openrec_${1}_$(date +"%Y%m%d_%H%M%S").ts"
      ffmpeg -i $(streamlink --stream-url $LIVE_URL best) -codec copy -f mpegts $FNAME
    fi

    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after 30 seconds..."
    sleep 30
  done

else
  echo "usage: $0 openrec_id"
fi
