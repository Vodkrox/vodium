#!/usr/bin/env python3
import json
import os
import re
import subprocess
import time

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.realpath(__file__))))
try:
    with open(os.path.join(ROOT, "config.json")) as f:
        _display = json.load(f).get("display", {})
except (OSError, ValueError):
    _display = {}
INTERNAL = _display.get("internal_monitor", "")
INTERNAL_SCALE = str(_display.get("internal_scale", 1))
INTERVAL = 2


def hyprctl(*args):
    return subprocess.run(["hyprctl", *args], capture_output=True, text=True)


def monitors():
    r = hyprctl("-j", "monitors", "all")
    return json.loads(r.stdout) if r.returncode == 0 and r.stdout else None


def modes(mon):
    out = []
    for m in mon.get("availableModes", []):
        match = re.match(r"(\d+)x(\d+)@([\d.]+)Hz", m)
        if match:
            w, h, hz = match.groups()
            out.append((int(w), int(h), round(float(hz) * 1000)))
    if not out:
        out = [(mon["width"], mon["height"], round(mon["refreshRate"] * 1000))]
    return out


def best_mode(mon):
    return max(modes(mon), key=lambda m: (m[2], m[0] * m[1]))


def apply():
    mons = monitors()
    if not mons:
        return
    externals = {m["name"]: m for m in mons if m["name"] != INTERNAL}
    if not externals:
        internal = next((m for m in mons if m["name"] == INTERNAL), None)
        if internal and internal.get("disabled"):
            hyprctl("keyword", "monitor", f"{INTERNAL},preferred,auto,{INTERNAL_SCALE}")
        return

    chosen = max(externals, key=lambda n: (best_mode(externals[n])[2], n))
    w, h, hz = best_mode(externals[chosen])
    mon = externals[chosen]
    cur = (mon["width"], mon["height"], round(mon["refreshRate"] * 1000))
    if mon.get("disabled") or cur != (w, h, hz):
        hyprctl("keyword", "monitor", f"{chosen},{w}x{h}@{hz / 1000:.2f},auto,1")
    for m in mons:
        if m["name"] != chosen and not m.get("disabled"):
            hyprctl("keyword", "monitor", f"{m['name']},disable")


def main():
    while True:
        try:
            apply()
        except Exception:
            pass
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
