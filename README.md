# kevin.sysmon

An [Omarchy](https://omarchy.org/) shell bar widget showing live system stats:

- `󰻠` CPU usage % (two `/proc/stat` samples 0.4s apart)
- `󰈐` fan RPM (highest `/sys/class/hwmon/hwmon*/fan*_input`; `--` when unavailable)
- `󰋊` disk used % on `/` (`df -Pk /`)
- `󰍛` memory used % (`1 − MemAvailable/MemTotal` from `/proc/meminfo`)

All three percentages use the same "used" convention: higher means
busier/fuller. Hover a button for the full tooltip (absolute free space, used
percentage, memory total). Click to refresh immediately. Data refreshes every
5 seconds.

## Install

```sh
git clone https://github.com/zhaoyul/omarchy-sysmon.git \
  ~/.config/omarchy/plugins/kevin.sysmon

omarchy-shell shell rescanPlugins
omarchy plugin enable kevin.sysmon
omarchy bar move kevin.sysmon --section right --after omarchy.monitor
```

The last two commands place the widget on the right side of the bar; adjust
`--section` / `--after` to taste. `shell.json` hot-reloads on save. If a change
does not show up, force a reload with `omarchy restart shell`.

Validate the plugin manifest with:

```sh
omarchy plugin validate ~/.config/omarchy/plugins/kevin.sysmon
```

## Files

- `manifest.json` — plugin declaration (`bar-widget`, id `kevin.sysmon`)
- `BarWidget.qml` — UI, timer, process output parsing, tooltips
- `stats.sh` — shell probe; prints 8 lines consumed by `BarWidget.qml`
- `i18n/en.json`, `i18n/zh-CN.json` — tooltip strings

## Change the refresh interval

Edit `interval: 5000` in `BarWidget.qml` (milliseconds). Saved plugin files
hot-reload automatically.

## Requirements

- Omarchy shell (Quickshell) with `qs.Commons` / `qs.Ui` modules
- Linux with `/proc/stat`, `/proc/meminfo`, `/sys/class/hwmon`, `df`, `awk`, `bash`
