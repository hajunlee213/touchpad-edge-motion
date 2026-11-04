#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] This script must be run with root privileges (sudo)." >&2
    exit 1
fi

BIN_SRC="${SCRIPT_DIR}/edge_motion.py"
BIN_DEST="/usr/local/bin/touchpad-edge-motion"
SERVICE_SRC="${SCRIPT_DIR}/touchpad-edge-motion.service"
SERVICE_DEST="/etc/systemd/system/touchpad-edge-motion.service"

for f in "${BIN_SRC}" "${SERVICE_SRC}"; do
    if [ ! -f "$f" ]; then
        echo "[ERROR] File not found: $f" >&2
        exit 1
    fi
done

# 1. Copy the executable binary and set permissions
echo "-> Installing /usr/local/bin/touchpad-edge-motion..."
cp "${BIN_SRC}" "${BIN_DEST}"
chmod 755 "${BIN_DEST}"

# 2. Set up the uinput udev rule (/etc/udev/rules.d/99-uinput.rules)
echo "-> Configuring uinput udev permission rule..."
UDEV_RULE="/etc/udev/rules.d/99-uinput.rules"
cat << 'RULE' > "${UDEV_RULE}"
KERNEL=="uinput", GROUP="input", MODE="0660", TAG+="uaccess", OPTIONS+="static_node=uinput"
RULE
chmod 644 "${UDEV_RULE}"
udevadm control --reload-rules || true
udevadm trigger 2>/dev/null || true

# 3. Add the target user to the input group
TARGET_USER="${SUDO_USER:-$USER}"
if [ "$TARGET_USER" != "root" ] && id "$TARGET_USER" >/dev/null 2>&1; then
    echo "-> Adding user '${TARGET_USER}' to the input group..."
    usermod -aG input "$TARGET_USER" || true
fi

# 4. Copy and register the systemd service unit file
echo "-> Registering ${SERVICE_DEST}..."
cp "${SERVICE_SRC}" "${SERVICE_DEST}"
chmod 644 "${SERVICE_DEST}"

echo "-> Reloading systemd daemon and enabling/starting the service..."
systemctl daemon-reload
systemctl enable --now touchpad-edge-motion

# 5. Check runtime status
if systemctl is-active --quiet touchpad-edge-motion; then
    echo "[SUCCESS] touchpad-edge-motion service is running normally."
else
    echo "[WARN] Please check the status of the touchpad-edge-motion service:"
    systemctl status touchpad-edge-motion --no-pager || true
fi
