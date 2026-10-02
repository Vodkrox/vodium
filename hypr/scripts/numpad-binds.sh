#!/bin/sh
out="$(dirname "$(readlink -f "$0")")/../numpad-binds.conf"
if [ "$1" = "0" ]; then
    cat > "$out.tmp" <<CONF
bind = , KP_Left, movefocus, l
bind = , KP_Right, movefocus, r
bind = , KP_Up, movefocus, u
bind = , KP_Down, movefocus, d
CONF
else
    : > "$out.tmp"
fi
mv "$out.tmp" "$out"
hyprctl reload >/dev/null 2>&1
