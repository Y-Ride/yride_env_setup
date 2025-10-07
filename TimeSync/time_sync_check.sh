#!/bin/bash

GRAY="\033[0;37m"
NC="\033[0m"
TAB=$'\t'

if [[ $EUID -ne 0 ]]; then

    echo "Script requires sudo, relaunching with sudo..."
    exec sudo -E "$0" "$@"

else
    if [[ -z "$PI_STATIC_IP" ]]; then
        echo "PI_STATIC_IP is not set. Please relaunch with 'sudo -E $0 $@'"
        exit 1
    fi
    
        # Run remote command and format output
    ssh yride@$PI_STATIC_IP "source ~/time_sync_verification/clock_ptp_check.sh && check_ptp_clocks" \
        | while IFS= read -r line; do
            echo -e "${GRAY}${TAB}${line}${NC}"
        done

    var=${PIPESTATUS[0]}  # Capture the return code of the ssh command

    echo "Key for return:"
    echo "  0 -> Clocks were already synchronized"
    echo "  1 -> Clocks were not synchronized but now they are"
    echo "  2 -> Error: Clocks are not synchronized"
    echo "  3 -> PPS is not being read from GPS"
    echo "Remote check_ptp_clocks returned $var"

    if [[ $var -eq 0 ]]; then
        echo "✅ Clock sync OK"
    elif [[ $var -eq 1 ]]; then
        echo "Clock sync failed AT LEAST once. "
        echo "Resetting Jetson ptp, phc2shm, and chrony services..."

        sudo systemctl daemon-reload
        sudo systemctl restart ptp4l.service phc2shm.service chrony

        echo "Resetting services complete. "
        echo "Resetting ouster lidar ptp..."
        
        restart_all_ouster_ptp

        echo "Resetting lidar ptp complete."
        
    elif [[ $var -eq 3 ]]; then
        echo "Wait for GPS to initialize or move to new area with GPS"
    else
        echo "❌ Clock sync FAILED. Fix before collecting any data!!!"
    fi

fi
