#!/bin/bash
# Twitch Live Stream Recorder

if [[ ! -n "$1" ]]; then
  echo "usage: $0 twitch_id [format] [loop|once] [interval]"
  exit 1
fi

# Record the highest quality available by default
FORMAT="${2:-best}"
INTERVAL="${4:-10}"

while true; do
  # Monitor live streams of specific channel
  while true; do
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX Try to get current live stream of twitch.tv/$1"

    # Get the m3u8 address with streamlink
    M3U8_URL=$(streamlink --stream-url "twitch.tv/$1" "$FORMAT")
    (echo "$M3U8_URL" | grep -q ".m3u8") && break

    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after $INTERVAL seconds..."
    sleep $INTERVAL
  done

  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="twitch_${1}_$(date +"%Y%m%d_%H%M%S").ts"
  echo "$LOG_PREFIX Start recording, stream saved to \"$FNAME\"."
  echo "$LOG_PREFIX Use command \"tail -f $FNAME.log\" to track recording progress."

  # Start recording
  ffmpeg -i "$M3U8_URL" -codec copy -f mpegts "$FNAME" > "$FNAME.log" 2>&1

  # Exit if we just need to record current stream
  LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
  echo "$LOG_PREFIX Live stream recording stopped."
  [[ "$3" == "once" ]] && break
done
