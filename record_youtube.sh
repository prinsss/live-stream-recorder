#!/bin/bash
# YouTube Live Stream Recorder

if [[ ! -n "$1" ]]; then
  echo "usage: $0 youtube_channel_id|live_url [format] [loop|once] [interval]"
  exit 1
fi

# Construct full URL if only channel id given
LIVE_URL=$1
[[ "$1" == "http"* ]] || LIVE_URL="https://www.youtube.com/channel/$1/live"

# Record the highest quality available by default
FORMAT="${2:-best}"
INTERVAL="${4:-10}"

while true; do
  # Monitor live streams of specific channel
  while true; do
    LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
    echo "$LOG_PREFIX Checking \"$LIVE_URL\"..."

    # Check if live stream available with wget
    (wget -q -O- "$LIVE_URL" | grep -q '\\"isLive\\":true') && break

    echo "$LOG_PREFIX The stream is not available now."
    echo "$LOG_PREFIX Retry after $INTERVAL seconds..."
    sleep $INTERVAL
  done

  # TODO: Use alternative script to retrieve metadata more efficiently.
  # Get metadata with youtube-dl when live stream is ready
  METADATA=$(youtube-dl --get-id --get-title --get-description \
    --no-playlist --playlist-items 1 "$LIVE_URL" 2>/dev/null)

  # Extract video id of live stream
  ID=$(echo "$METADATA" | sed -n '2p')

  # Record using MPEG-2 TS format to avoid broken file caused by interruption
  FNAME="youtube_${ID}_$(date +"%Y%m%d_%H%M%S").ts"
  # Also save the metadate to file
  echo "$METADATA" > "$FNAME.info.txt"

  # Print logs
  echo "$LOG_PREFIX Start recording, metadata saved to \"$FNAME.info.txt\"."
  echo "$LOG_PREFIX Use command \"tail -f $FNAME.log\" to track recording progress."

  # Start recording
  # ffmpeg -i "$M3U8_URL" -codec copy -f mpegts "$FNAME" > "$FNAME.log" 2>&1

  # Use streamlink to record for HLS seeking support
  streamlink --hls-live-restart --loglevel trace -o "$FNAME" \
    "https://www.youtube.com/watch?v=${ID}" "$FORMAT" > "$FNAME.log" 2>&1

  # Exit if we just need to record current stream
  LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
  echo "$LOG_PREFIX Live stream recording stopped."
  [[ "$3" == "once" ]] && break
done
