# touchpad-edge-motion

**English** | [한국어](README.ko.md)

A Linux touchpad daemon that keeps the cursor moving while a drag is held at the touchpad edge. It supports both click-drag and tap-and-drag (double-tap and hold).

## How It Works

- Finds the device whose name contains `touchpad` in `/proc/bus/input/devices` and reads from the matching `/dev/input/event*`.
- Moves the cursor through a virtual pointer created via `/dev/uinput`.
- Does not use any desktop environment API (gsettings, D-Bus, etc.), so it works regardless of X11/Wayland or GNOME/KDE.
- Uses only the Python 3 standard library.

## Requirements

- systemd (the installer registers the service)
- `/usr/bin/python3`
- `uinput` kernel module (if `/dev/uinput` is missing, run `sudo modprobe uinput`)
- Tap-and-drag must be enabled in your compositor for tap-and-drag to work.

## Installation

```bash
sudo ./install.sh
```

Installed items:

| Path | Description |
|---|---|
| `/usr/local/bin/touchpad-edge-motion` | Daemon (`edge_motion.py`) |
| `/etc/systemd/system/touchpad-edge-motion.service` | systemd service |
| `/etc/udev/rules.d/99-uinput.rules` | Permission rule for `/dev/uinput` |

The user is added to the `input` group (takes effect after logging back in).

## Manual Run / Options

```bash
sudo python3 edge_motion.py --help
sudo python3 edge_motion.py --device /dev/input/event6
```

If automatic touchpad detection fails, specify the device directly with `--device`.

## Status / Logs / Uninstall

```bash
systemctl status touchpad-edge-motion
journalctl -u touchpad-edge-motion -f
```

```bash
sudo systemctl disable --now touchpad-edge-motion
sudo rm -f /etc/systemd/system/touchpad-edge-motion.service /usr/local/bin/touchpad-edge-motion /etc/udev/rules.d/99-uinput.rules
sudo systemctl daemon-reload
```
