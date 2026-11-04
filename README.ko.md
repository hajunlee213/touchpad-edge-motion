# touchpad-edge-motion

[English](README.md) | **한국어**

Linux 터치패드 가장자리 연속 이동 데몬. 드래그 중 손가락이 터치패드 가장자리에 닿으면 커서를 계속 이동시킵니다. 물리 클릭 드래그와 탭 앤 드래그(더블 탭 홀드)를 모두 지원합니다.

A Linux touchpad daemon that keeps the cursor moving while a drag is held at the touchpad edge (click-drag and tap-and-drag).

## 동작 방식

- `/proc/bus/input/devices`에서 이름에 `touchpad`가 들어간 장치를 찾아 `/dev/input/event*`를 읽습니다.
- `/dev/uinput` 가상 포인터로 커서를 움직입니다.
- 데스크톱 환경 API(gsettings, D-Bus 등)를 쓰지 않으므로 X11/Wayland, GNOME/KDE 등과 무관합니다.
- Python 3 표준 라이브러리만 사용합니다.

## 요구 사항

- systemd (설치 스크립트가 서비스를 등록합니다)
- `/usr/bin/python3`
- `uinput` 커널 모듈 (`/dev/uinput`이 없으면 `sudo modprobe uinput`)
- 컴포지터의 tap-and-drag 설정이 켜져 있어야 탭 앤 드래그가 동작합니다.

## 설치

```bash
sudo ./install.sh
```

설치되는 항목:

| 경로 | 설명 |
|---|---|
| `/usr/local/bin/touchpad-edge-motion` | 데몬 (`edge_motion.py`) |
| `/etc/systemd/system/touchpad-edge-motion.service` | systemd 서비스 |
| `/etc/udev/rules.d/99-uinput.rules` | `/dev/uinput` 권한 룰 |

사용자는 `input` 그룹에 추가됩니다(재로그인 후 적용).

## 수동 실행 / 옵션

```bash
sudo python3 edge_motion.py --help
sudo python3 edge_motion.py --device /dev/input/event6
```

터치패드 이름 자동 탐지가 실패하면 `--device`로 직접 지정합니다.

## 확인 / 제거

```bash
systemctl status touchpad-edge-motion
journalctl -u touchpad-edge-motion -f
```

```bash
sudo systemctl disable --now touchpad-edge-motion
sudo rm -f /etc/systemd/system/touchpad-edge-motion.service /usr/local/bin/touchpad-edge-motion /etc/udev/rules.d/99-uinput.rules
sudo systemctl daemon-reload
```
