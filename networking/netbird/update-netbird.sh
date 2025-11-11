#!/bin/bash
set -euo pipefail

#source "$(dirname "$0")/../utils/log.sh"
#source "$(dirname "$0")/../utils/check_root.sh"

log "=== [$(date)] Start NetBird update ==="

curl -fsSL https://pkgs.netbird.io/install.sh | bash
systemctl restart netbird

if systemctl is-active --quiet netbird; then
	log "✅ NetBird has been started."
else
	log "❌ NetBird did not start. Please check logs."
	exit
fi

log "=== Update completed ==="
