#!/bin/sh

case "$1" in
camera)
    icon="󰄀"
    fuser /dev/video* >/dev/null 2>&1 && active=1
    ;;
mic)
    icon="󰍬"
    n=$(pactl --format=json list source-outputs 2>/dev/null \
        | jq '[.[] | select(.corked == false) | select(.properties["stream.capture.sink"] != "true")] | length')
    [ "${n:-0}" -gt 0 ] && active=1
    ;;
esac

if [ -n "$active" ]; then
    printf '{"text":"%s","class":"active"}\n' "$icon"
else
    printf '{"text":""}\n'
fi
