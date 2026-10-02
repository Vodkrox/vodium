# vodium

## Dependencies

- Required: `hyprland`, `quickshell`, `python3`, `socat`, `awww` (wallpaper), `pipewire` with `wpctl` and `pactl`, `brightnessctl`, `NetworkManager` (`nmcli`), `cliphist`, `wl-clipboard`, `jq`, `fuser`.
- Optional depending on `config.json`: `tuned` (power profiles), `alacritty`, `swaylock`, `kcalc`.

## Install

Package names may vary between releases.

### Debian / Ubuntu

```
sudo apt install -t trixie-backports hyprland quickshell
sudo apt install python3 socat pipewire pipewire-pulse wireplumber pulseaudio-utils \
  brightnessctl network-manager cliphist wl-clipboard jq psmisc
```

`hyprland` and `quickshell` come from `trixie-backports` (Debian 13). `awww` is not packaged and must be built from source.

### Fedora / RHEL

```
sudo dnf copr enable errornointernet/quickshell
sudo dnf install hyprland quickshell python3 socat pipewire-utils wireplumber pulseaudio-utils \
  brightnessctl NetworkManager wl-clipboard jq psmisc cliphist
```

`awww` must be built from source. RHEL does not ship Hyprland.

### Arch

```
sudo pacman -S hyprland quickshell python socat pipewire pipewire-pulse wireplumber libpulse \
  brightnessctl networkmanager cliphist wl-clipboard jq psmisc
paru -S awww
```

### Void

```
sudo xbps-install -S hyprland quickshell python3 socat pipewire wireplumber pulseaudio-utils \
  brightnessctl NetworkManager cliphist wl-clipboard jq psmisc
```

`awww` must be built from source.

### Gentoo

```
sudo eselect repository enable guru
sudo emerge --ask gui-wm/hyprland gui-apps/quickshell gui-apps/awww dev-lang/python \
  net-misc/socat media-video/pipewire media-video/wireplumber media-sound/pulseaudio-daemon \
  app-misc/brightnessctl net-misc/networkmanager app-misc/cliphist gui-apps/wl-clipboard \
  app-misc/jq sys-process/psmisc
```

Optional on all distros: `tuned`, `alacritty`, `swaylock`, `kcalc`.

### Building from source

Needs `git` and the Rust toolchain (`cargo`).

`awww`:

```
git clone https://codeberg.org/LGFae/awww
cd awww
cargo build --release
install -Dm755 target/release/awww target/release/awww-daemon -t ~/.local/bin
```

`quickshell` (also needs `cmake`, `ninja` and the Qt 6 development packages; see the [install guide](https://quickshell.org/docs/guide/install-setup/)):

```
git clone https://github.com/quickshell-mirror/quickshell
cd quickshell
cmake -GNinja -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build
```

## Setup

1. Clone or copy the repo to `~/.config/vodium`.
2. Link the Hyprland configuration:
   ```
   ln -s vodium/hypr ~/.config/hypr
   ```
3. Generate the machine configuration:
   ```
   hypr/scripts/generate-conf.py
   ```
   If `config.json` doesn't exist, it creates it with detected values (backlight, LEDs, battery, internal monitor) and generic ones for the rest. It then writes `hypr/local.conf` and an empty `numpad-binds.conf`.
4. Review `config.json` and adjust whatever is needed (keyboard, wallpaper, monitors, GPU…).
5. Log in to Hyprland. Quickshell starts by itself via `exec-once`.

## config.json

Hyprland can't read JSON, so the `display` and `hypr` sections are only applied when running `hypr/scripts/generate-conf.py` and reloading Hyprland (`hyprctl reload`; for `drm_devices` and the monitor you may need to restart the session). Quickshell picks up everything else live when the file is saved.

| Section | Keys |
| --- | --- |
| `wallpaper` | `path`: background image (accepts `~/`) |
| `osd` | `sysfs_backlight_max`, `sysfs_backlight_current`, `sysfs_capslock_led`, `sysfs_numlock_led`: sysfs paths for brightness and lock LEDs |
| `bar` | `volume_scroll_step`: volume step for the scroll wheel |
| `cpu` | `hot_ghz_threshold`, `hot_usage_threshold`, `hwmon_name` (temperature sensor), `temp_ring`, `freq_ring` |
| `battery` | `warning_thresholds`, `sysfs_battery`, `sysfs_ac_glob` |
| `power` | `states`: power profile for `charging`, `battery` and `low` (edited from the power menu) |
| `gpu` | `pci_device`: `runtime_status` path of the discrete GPU (empty to disable the warning) |
| `menus` | `tuned_adm_path` |
| `chains` | `hot_speed_multiplier` |
| `display` | `internal_monitor`, `internal_scale`, `drm_devices` |
| `hypr` | `kb_layout`, `quickshell_command`, `terminal`, `lock_command`, `calculator` |

## Shortcuts

`SUPER` is the main key.

| Shortcut | Action |
| --- | --- |
| `SUPER + Q` | Launcher |
| `SUPER + B` | Clipboard |
| `SUPER + T` | Tray |
| `SUPER + N` | Notifications |
| `SUPER + Enter` | Terminal |
| `SUPER + L` | Lock screen |
| `SUPER + W` | Close window |
| `SUPER + F` | Fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + ←/→` | Move window |
| `SUPER + 1…9` | Switch workspace |
| `SUPER + SHIFT + 1…7` | Move window to a workspace |
| `SUPER + SHIFT + 8/9` | Previous / next workspace |
| `SUPER + M` | Exit Hyprland |

Media keys control volume, microphone, brightness and the calculator. With Num Lock off, the numpad arrow keys move focus.

## Local data

These files are generated at runtime and not versioned (see `.gitignore`): `config.json`, `hypr/local.conf`, `hypr/numpad-binds.conf`, `quickshell/osd/pinned.json`, `quickshell/osd/power.json` and `quickshell/osd/clipboard-pins.json`.

## Notes

- Quickshell blocks relative paths that leave the shell directory (`Qt.resolvedUrl("../..")` returns `qrc:/qs-blackhole`). To reach `config.json` and the scripts in `hypr/`, `Quickshell.shellPath()` is used.
- `quickshell/osd/scripts/claude-hook.sh` is meant to be hooked into Claude Code's hooks and feed the status indicator in the bar.
