#!/usr/bin/env bash
set -e

LOGFILE="/var/log/flexinit_update.log"
WAIT_INTERVAL=2
WAIT_TIMEOUT=60

log() {
	local message="$1"
	echo "$(date '+%Y-%m-%d %H:%M:%S') | $message" | tee -a "$LOGFILE"
}

detect_init_system() {
	if command -v systemctl >/dev/null 2>&1; then
		INIT_SYSTEM="systemd"
	elif command -v rc-service >/dev/null 2>&1; then
		INIT_SYSTEM="openrc"
	elif command -v service >/dev/null 2>&1; then
		INIT_SYSTEM="sysvinit"
	else
		log "Unsupported init system"
		exit 1
	fi
	log "Detected init system: $INIT_SYSTEM"
}

service_action() {
	local action="$1"
	local svc="$2"
	case "$INIT_SYSTEM" in
	systemd)
		sudo systemctl "$action" "$svc"
		;;
	openrc)
		sudo rc-service "$svc" "$action"
		;;
	sysvinit)
		sudo service "$svc" "$action"
		;;
	esac
}

check_service_running() {
	local svc="$1"
	case "$INIT_SYSTEM" in
	systemd)
		systemctl is-active --quiet "$svc"
		;;
	openrc)
		rc-service "$svc" status >/dev/null 2>&1
		;;
	sysvinit)
		service "$svc" status >/dev/null 2>&1
		;;
	esac
}

wait_for_service() {
	local svc="$1"
	local elapsed=0

	while ! check_service_running "$svc"; do
		if [ "$elapsed" -ge "$WAIT_TIMEOUT" ]; then
			log "Timeout: $svc did not start within $WAIT_TIMEOUT seconds"
			exit 1
		fi
		log "Waiting for $svc service..."
		sleep "$WAIT_INTERVAL"
		elapsed=$((elapsed + WAIT_INTERVAL))
	done
	log "$svc service is running!"
}

main() {
	detect_init_system

	LATEST_VERSION=$(curl -s https://api.github.com/repos/netbirdio/netbird/releases/latest | grep -oE '"tag_name": "[^"]+"' | cut -d'"' -f4 | sed 's/^v//')
	log "Latest Netbird version: $LATEST_VERSION"

	INSTALLED_VERSION=$(netbird version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
	log "Installed Netbird version: ${INSTALLED_VERSION:-not installed}"

	if [ "$INSTALLED_VERSION" != "$LATEST_VERSION" ]; then
		log "Updating Netbird to $LATEST_VERSION..."

		service_action stop netbird

		curl -fsSLO https://pkgs.netbird.io/install.sh | sudo bash

		service_action start netbird

		wait_for_service netbird

		log "Netbird updated to $LATEST_VERSION"

	else
		log "Netbird is already up to date."
	fi
}

main
