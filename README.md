# vodkrox-rice

Configuración de escritorio para [Hyprland](https://hyprland.org) con una shell propia hecha en [Quickshell](https://quickshell.org): barra lateral, OSD, lanzador, portapapeles, notificaciones, bandeja y menús de red, bluetooth, sonido y energía.

Nada en el repo es específico de una máquina. Todo lo que depende del hardware o de tus preferencias vive en `config.json`.

## Estructura

```
config.json                 Ajustes de la máquina (se crea solo, no se versiona)
hypr/
  hyprland.conf             Configuración genérica de Hyprland
  local.conf                Generado desde config.json (no se versiona)
  numpad-binds.conf         Generado en ejecución según el estado de Bloq Num
  scripts/
    generate-conf.py        Crea config.json si falta y genera local.conf
    auto-output.py          Activa solo el monitor externo cuando está conectado
    numpad-binds.sh         Atajos del teclado numérico según Bloq Num
quickshell/osd/             Shell de Quickshell (QML)
  scripts/                  Helpers: privacidad (cámara/micro) y estado de Claude Code
```

## Dependencias

- Obligatorias: `hyprland`, `quickshell`, `python3`, `socat`, `awww` (fondo de pantalla), `pipewire` con `wpctl` y `pactl`, `brightnessctl`, `NetworkManager` (`nmcli`), `cliphist`, `wl-clipboard`, `jq`, `fuser`.
- Opcionales según `config.json`: `tuned` (perfiles de energía), `alacritty`, `swaylock`, `kcalc`.

## Instalación

1. Clona o copia el repo en `~/.config/vodkrox-rice`.
2. Enlaza la configuración de Hyprland:
   ```
   ln -s vodkrox-rice/hypr ~/.config/hypr
   ```
3. Genera la configuración de la máquina:
   ```
   hypr/scripts/generate-conf.py
   ```
   Si no existe `config.json`, lo crea con valores detectados (backlight, LEDs, batería, monitor interno) y genéricos para el resto. Después escribe `hypr/local.conf` y un `numpad-binds.conf` vacío.
4. Revisa `config.json` y ajusta lo que haga falta (teclado, wallpaper, monitores, GPU…).
5. Inicia sesión en Hyprland. Quickshell se lanza solo con `exec-once`.

## config.json

Hyprland no sabe leer JSON, así que las secciones `display` e `hypr` solo se aplican al ejecutar `hypr/scripts/generate-conf.py` y recargar Hyprland (`hyprctl reload`; para `drm_devices` y el monitor puede hacer falta reiniciar la sesión). El resto lo recoge Quickshell en caliente al guardar el archivo.

| Sección | Claves |
| --- | --- |
| `wallpaper` | `path`: imagen de fondo (acepta `~/`) |
| `osd` | `sysfs_backlight_max`, `sysfs_backlight_current`, `sysfs_capslock_led`, `sysfs_numlock_led`: rutas sysfs del brillo y los LEDs de bloqueo |
| `bar` | `volume_scroll_step`: paso de volumen con la rueda |
| `cpu` | `hot_ghz_threshold`, `hot_usage_threshold`, `hwmon_name` (sensor de temperatura), `temp_ring`, `freq_ring` |
| `battery` | `warning_thresholds`, `sysfs_battery`, `sysfs_ac_glob` |
| `power` | `states`: perfil de energía para `charging`, `battery` y `low` (se edita desde el menú de energía) |
| `gpu` | `pci_device`: ruta `runtime_status` de la GPU dedicada (vacío para desactivar el aviso) |
| `menus` | `tuned_adm_path` |
| `chains` | `hot_speed_multiplier` |
| `display` | `internal_monitor`, `internal_scale`, `drm_devices` |
| `hypr` | `kb_layout`, `quickshell_command`, `terminal`, `lock_command`, `calculator` |

## Atajos

`SUPER` es la tecla principal.

| Atajo | Acción |
| --- | --- |
| `SUPER + Q` | Lanzador |
| `SUPER + B` | Portapapeles |
| `SUPER + T` | Bandeja |
| `SUPER + N` | Notificaciones |
| `SUPER + Enter` | Terminal |
| `SUPER + L` | Bloquear pantalla |
| `SUPER + W` | Cerrar ventana |
| `SUPER + F` | Pantalla completa |
| `SUPER + V` | Alternar flotante |
| `SUPER + ←/→` | Mover ventana |
| `SUPER + 1…9` | Cambiar de espacio de trabajo |
| `SUPER + SHIFT + 1…7` | Mover ventana a un espacio de trabajo |
| `SUPER + SHIFT + 8/9` | Espacio anterior / siguiente |
| `SUPER + M` | Salir de Hyprland |

Las teclas multimedia controlan volumen, micrófono, brillo y calculadora. Con Bloq Num desactivado, las flechas del teclado numérico mueven el foco.

## Datos locales

Estos archivos se generan en ejecución y no se versionan (ver `.gitignore`): `config.json`, `hypr/local.conf`, `hypr/numpad-binds.conf`, `quickshell/osd/pinned.json`, `quickshell/osd/power.json` y `quickshell/osd/clipboard-pins.json`.

## Notas

- Quickshell bloquea las rutas relativas que salen del directorio de la shell (`Qt.resolvedUrl("../..")` devuelve `qrc:/qs-blackhole`). Para llegar a `config.json` y a los scripts de `hypr/` se usa `Quickshell.shellPath()`.
- `quickshell/osd/scripts/claude-hook.sh` está pensado para engancharse a los hooks de Claude Code y alimentar el indicador de estado de la barra.
