#!/bin/bash

# set -euo pipefail

# Colors for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Timeout (seconds) for checking connectivity
PING_TIMEOUT=2
CURL_TIMEOUT=3

# Function to log messages
log() {
    local level="$1"; shift
    echo -e "${level}${*}${NC}"
}

# Check if lidar is reachable
check_for_lidar() {
    local hostname="$1"
    if ping -c 1 -W "$PING_TIMEOUT" "$hostname" &>/dev/null; then
        log "$GREEN" "[OK] LIDAR at ${hostname} is reachable."
        return 0
    else
        log "$RED" "[ERROR] LIDAR at ${hostname} is not reachable!"
        return 1
    fi
}

# Restart PTP service on a single lidar
restart_ouster_ptp() {
    local hostname="$1"

    if [[ -z "$hostname" ]]; then
        log "$RED" "[ERROR] No hostname provided to restart_ouster_ptp()."
        return 1
    fi

    if ! check_for_lidar "$hostname"; then
        log "$YELLOW" "[WARN] Skipping ${hostname} — not reachable."
        return 1
    fi

    log "$YELLOW" "Restarting PTP on ${hostname}..."

    local api_url="http://${hostname}/api/v1/time/ptp/profile"

    if ! curl -fsS -m "$CURL_TIMEOUT" -X PUT "$api_url" \
        -H "Content-Type: application/json" \
        --data-raw '"gptp"' >/dev/null; then
        log "$RED" "[ERROR] Failed to set PTP profile to 'gptp' on ${hostname}"
        return 1
    fi

    sleep 1

    if ! curl -fsS -m "$CURL_TIMEOUT" -X PUT "$api_url" \
        -H "Content-Type: application/json" \
        --data-raw '"default"' >/dev/null; then
        log "$RED" "[ERROR] Failed to reset PTP profile to 'default' on ${hostname}"
        return 1
    fi

    log "$GREEN" "[SUCCESS] Restarted PTP on ${hostname}"
}

restart_all_ouster_ptp() {
    restart_ouster_ptp "${LIDAR_STATIC_IP_TOP}"
    restart_ouster_ptp "${LIDAR_STATIC_IP_LEFT}"
    restart_ouster_ptp "${LIDAR_STATIC_IP_RIGHT}"
    restart_ouster_ptp "${LIDAR_STATIC_IP_FRONT}"
    restart_ouster_ptp "${LIDAR_STATIC_IP_BACK}"
}