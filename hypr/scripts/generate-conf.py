#!/usr/bin/env python3
"""Genera hypr/local.lua a partir de config.json (ajustes específicos de cada máquina)."""
import glob
import json
import os
import re
import shutil

HERE = os.path.dirname(os.path.realpath(__file__))
HYPR = os.path.dirname(HERE)
ROOT = os.path.dirname(HYPR)

CONFIG = os.path.join(ROOT, "config.json")


def first(pattern, default=""):
    found = sorted(glob.glob(pattern))
    return found[0] if found else default


def internal_monitor():
    for p in sorted(glob.glob("/sys/class/drm/card*-eDP-*")):
        m = re.match(r"card\d+-(.+)", os.path.basename(p))
        if m:
            return m.group(1)
    return ""


def default_config():
    backlight = first("/sys/class/backlight/*")
    battery = first("/sys/class/power_supply/BAT*")
    return {
        "wallpaper": {"path": ""},
        "osd": {
            "sysfs_backlight_max": backlight + "/max_brightness" if backlight else "",
            "sysfs_backlight_current": backlight + "/brightness" if backlight else "",
            "sysfs_capslock_led": first("/sys/class/leds/*::capslock") + "/brightness" if first("/sys/class/leds/*::capslock") else "",
            "sysfs_numlock_led": first("/sys/class/leds/*::numlock") + "/brightness" if first("/sys/class/leds/*::numlock") else "",
        },
        "bar": {"volume_scroll_step": 0.05},
        "cpu": {
            "hot_ghz_threshold": 3.4,
            "hot_usage_threshold": 0.8,
            "temp_ring": {"min_c": 30, "max_c": 100, "hot_threshold_c": 85},
            "freq_ring": {"min_speed_deg_s": 90, "max_speed_deg_s": 900},
            "hwmon_name": "coretemp",
        },
        "battery": {
            "warning_thresholds": [20, 10, 5],
            "sysfs_battery": battery,
            "sysfs_ac_glob": "/sys/class/power_supply/A*/online",
        },
        "power": {"states": {"charging": "none", "battery": "none", "low": "none"}},
        "gpu": {"pci_device": ""},
        "menus": {"tuned_adm_path": shutil.which("tuned-adm") or "tuned-adm"},
        "chains": {"hot_speed_multiplier": 10},
        "display": {"internal_monitor": internal_monitor(), "internal_scale": 1, "drm_devices": ""},
        "hypr": {
            "kb_layout": "us",
            "quickshell_command": "qs",
            "terminal": "alacritty",
            "lock_command": "swaylock --color 000000",
            "calculator": "kcalc",
        },
    }


if not os.path.exists(CONFIG):
    with open(CONFIG, "w") as f:
        json.dump(default_config(), f, indent=2, ensure_ascii=False)
        f.write("\n")
    print(f"Creado {CONFIG} con valores por defecto")

cfg = json.load(open(CONFIG))
d, h = cfg.get("display", {}), cfg.get("hypr", {})
qs = f"{os.path.expanduser(h.get('quickshell_command', 'qs'))} -p {os.path.join(ROOT, 'quickshell', 'osd')}"

def lua_str(value):
    return json.dumps(value, ensure_ascii=False)


lines = [
    "-- Generado por scripts/generate-conf.py desde config.json. No editar.",
    f"local qs = {lua_str(qs)}",
    f"local terminal = {lua_str(h.get('terminal', 'alacritty'))}",
    f"local lock = {lua_str(h.get('lock_command', 'swaylock'))}",
    f"local calculator = {lua_str(h.get('calculator', 'kcalc'))}",
    f"local autoOutput = {lua_str(os.path.join(HERE, 'auto-output.py'))}",
    "",
    "hl.config({",
    "    input = {",
    f"        kb_layout = {lua_str(h.get('kb_layout', 'us'))},",
    "    },",
    "})",
]
if d.get("drm_devices"):
    lines.append(f"hl.env('AQ_DRM_DEVICES', {lua_str(d['drm_devices'])})")
if d.get("internal_monitor"):
    lines += [
        "hl.monitor({",
        f"    output = {lua_str(d['internal_monitor'])},",
        "    mode = 'preferred',",
        "    position = 'auto',",
        f"    scale = {d.get('internal_scale', 1)},",
        "})",
    ]
lines += [
    "",
    "return {",
    "    qs = qs,",
    "    terminal = terminal,",
    "    lock = lock,",
    "    calculator = calculator,",
    "    autoOutput = autoOutput,",
    "}",
]

with open(os.path.join(HYPR, "local.lua"), "w") as f:
    f.write("\n".join(lines) + "\n")
numpad = os.path.join(HYPR, "numpad-binds.lua")
if not os.path.exists(numpad):
    open(numpad, "w").close()
