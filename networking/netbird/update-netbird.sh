#!/bin/bash
set -euo pipefail

#source "$(dirname "$0")/../utils/log.sh"
#source "$(dirname "$0")/../utils/check_root.sh"

echo "=== [$(date)] Start NetBird update ==="

echo "=== [$(date)] Stopping NetBird service ==="

echo "Netbird is still running. Trying to stop the service"
while systemctl is-active --quiet netbird; do
	sleep 2
done

echo "Netbird is succesfully stopped."

echo "Downloading and installing latest package from source..."

curl -fsSL https://pkgs.netbird.io/install.sh | bash

echo "Starting Netbird "
systemctl restart netbird

if systemctl is-active --quiet netbird; then
	echo "✅ NetBird has been started."
else
	systemctl netbird status
	echo "❌ NetBird did not start. Please check logs."
	exit
fi

echo "=== Update completed ==="
