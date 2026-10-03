#!/bin/sh
out="$(dirname "$(readlink -f "$0")")/../numpad-binds.lua"
if [ "$1" = "0" ]; then
    cat > "$out.tmp" <<LUA
hl.bind("KP_Left", hl.dsp.focus({ direction = "left" }))
hl.bind("KP_Right", hl.dsp.focus({ direction = "right" }))
hl.bind("KP_Up", hl.dsp.focus({ direction = "up" }))
hl.bind("KP_Down", hl.dsp.focus({ direction = "down" }))
LUA
else
    : > "$out.tmp"
fi
mv "$out.tmp" "$out"
hyprctl reload >/dev/null 2>&1
