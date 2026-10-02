#!/bin/sh
dir="${XDG_RUNTIME_DIR:-/tmp}/claude-status"
mkdir -p "$dir"
id=$(sed -n 's/.*"session_id" *: *"\([^"]*\)".*/\1/p' | head -n1)
[ -n "$id" ] || exit 0
if [ "$1" = end ]; then rm -f "$dir/$id"; exit 0; fi
pid=$PPID
p=$$
while [ "$p" -gt 1 ]; do
    [ "$(cat /proc/$p/comm 2>/dev/null)" = claude ] && { pid=$p; break; }
    p=$(sed -n 's/^PPid:[[:space:]]*//p' /proc/$p/status 2>/dev/null)
    [ -n "$p" ] || break
done
echo "$1 $pid" > "$dir/$id"
