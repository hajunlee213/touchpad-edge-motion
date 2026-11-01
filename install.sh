#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# root 권한 확인
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] 이 스크립트는 root 권한(sudo)으로 실행해야 합니다." >&2
    exit 1
fi

BIN_SRC="${SCRIPT_DIR}/edge_motion.py"
BIN_DEST="/usr/local/bin/touchpad-edge-motion"
SERVICE_SRC="${SCRIPT_DIR}/touchpad-edge-motion.service"
SERVICE_DEST="/etc/systemd/system/touchpad-edge-motion.service"

for f in "${BIN_SRC}" "${SERVICE_SRC}"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] 파일을 찾을 수 없습니다: $f" >&2
        exit 1
    fi
done

# 1. 실행 바이너리 복사 및 권한 부여
echo "-> /usr/local/bin/touchpad-edge-motion 설치..."
cp "${BIN_SRC}" "${BIN_DEST}"
chmod 755 "${BIN_DEST}"

# 2. uinput udev 룰 설정 (/etc/udev/rules.d/99-uinput.rules)
echo "-> uinput udev 권한 룰 설정..."
UDEV_RULE="/etc/udev/rules.d/99-uinput.rules"
cat << 'RULE' > "${UDEV_RULE}"
KERNEL=="uinput", GROUP="input", MODE="0660", TAG+="uaccess", OPTIONS+="static_node=uinput"
RULE
chmod 644 "${UDEV_RULE}"
udevadm control --reload-rules || true
udevadm trigger 2>/dev/null || true

# 3. 대상 사용자를 input 그룹에 추가
TARGET_USER="${SUDO_USER:-$USER}"
if [ "$TARGET_USER" != "root" ] && id "$TARGET_USER" >/dev/null 2>&1; then
    echo "-> 사용자 '${TARGET_USER}'를 input 그룹에 등록..."
    usermod -aG input "$TARGET_USER" || true
fi

# 4. systemd 서비스 유닛 파일 복사 및 등록
echo "-> ${SERVICE_DEST} 등록..."
cp "${SERVICE_SRC}" "${SERVICE_DEST}"
chmod 644 "${SERVICE_DEST}"

echo "-> systemd 데몬 갱신 및 서비스 활성화/시작..."
systemctl daemon-reload
systemctl enable --now touchpad-edge-motion

# 5. 실행 상태 점검
if systemctl is-active --quiet touchpad-edge-motion; then
    echo "[SUCCESS] touchpad-edge-motion 서비스가 정상 실행 중입니다."
else
    echo "[WARN] touchpad-edge-motion 서비스 상태를 확인해 주세요:"
    systemctl status touchpad-edge-motion --no-pager || true
fi
