#!/bin/bash
set -euo pipefail

#source "$(dirname "$0")/../utils/log.sh"
#source "$(dirname "$0")/../utils/check_root.sh"

echo "=== [$(date)] Start NetBird update ==="

curl -fsSL https://pkgs.netbird.io/install.sh | bash
systemctl restart netbird

if systemctl is-active --quiet netbird; then
	echo "✅ NetBird has been started."
else
	echo "❌ Bird did not start. Please check logs."
	exit
fi

echo "=== Update completed ==="
