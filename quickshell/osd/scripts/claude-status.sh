#!/bin/sh
dir="${XDG_RUNTIME_DIR:-/tmp}/claude-status"
best=none; rank=0
for f in "$dir"/*; do
    [ -f "$f" ] || continue
    read -r state pid < "$f"
    if ! kill -0 "$pid" 2>/dev/null; then rm -f "$f"; continue; fi
    case $state in
        error) r=4 ;; waiting) r=3 ;; working) r=2 ;; ready) r=1 ;; *) continue ;;
    esac
    [ "$r" -gt "$rank" ] && { rank=$r; best=$state; }
done
echo "$best"
