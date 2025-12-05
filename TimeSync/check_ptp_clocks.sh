#!/bin/bash

check_ptp_clocks_return_key() {
    echo "Key for check_ptp_clock return:"
    echo "  0 -> Clocks were already synchronized"
    echo "  1 -> Clocks were not synchronized but should be now for pi, jetson, and lidars"
    echo "  2 -> Error: Clocks are not synchronized or couldn't read clocks"
    echo "  3 -> PPS is not being read from GPS"
    echo "  4 -> PPS is not being read from GPS, but clocks are synchronized"
    echo "  5 -> No static IP connection to $PI_HOSTNAME"
}

check_ptp_clocks()
{
    local ret=0
    local count=1
    local MAX_COUNT=2

    if [[ -z $PI_HOSTNAME ]]; then
        echo "Need to set the PI_HOSTNAME variable first!"
        return 5
    fi

    if [[ $HOSTNAME != $PI_HOSTNAME ]]; then
        echo "Connecting to $PI_HOSTNAME via SSH..."
        ssh yride@$PI_STATIC_IP "bash -lc 'source ~/yride_env_setup/custom_env.sh; check_ptp_clocks'" || { echo "SSH connection failed."; return 5; }
        ret=$?
        if [[ $ret -eq 255 ]]; then
            echo "SSH connection failed."
            return 5
        fi
        return $ret
    fi

    active_source=$(chronyc sources | awk '/^\#*\*/ {print $2}')

    if [[ "$active_source" == "PPS" ]]; then
        echo "✅ PPS is active"
    else
        ret=4
        echo "❌ PPS is NOT active. Either no GPS is being received or there is another issue."
        if [[ $- == *i* ]]; then # Check to see if terminal is interactive
            read -p "Proceed? [y/N]: " answer
            answer=${answer:-n}
        else
            answer=y
        fi

        if [[ $answer != [Yy] ]]; then
            echo "Cancelled."
            return 3
        fi
            
    fi

    LEAP_SECOND=37 
    THRESHOLD=0.5 # seconds
    sleep_duration=20

    
    while true; do

        # Parse PHC time safely
        phc_time=$(sudo phc_ctl /dev/ptp0 get | awk '/clock time/ {print $5}')
        sys_time=$(date +%s.%N)

        # Protect against empty output
        [[ -z "$phc_time" || -z "$sys_time" ]] && {
            echo "ERROR: Failed to read PHC or system time."
            return 2
        }

        # Compute diff using awk only (awk supports floats natively)
        diff=$(awk -v a="$phc_time" -v b="$sys_time" 'BEGIN{print a - b}')
        echo "PHC - System = $diff seconds"

        # Absolute offset (still pure awk)
        offset=$(awk -v x="$diff" -v l="$LEAP_SECOND" 'BEGIN{print (x<0? -x : x) - l}')
        echo "Offset: $offset (with one leap second, $LEAP_SECOND s, subtracted)"

        # Numerical comparison (no bc needed)
        greater=$(awk -v o="$offset" -v t="$THRESHOLD" 'BEGIN{print (o > t || o < -t)}')

        if [[ "$greater" -eq 1 ]]; then
            echo "Absolute offset too large! (threshold is $THRESHOLD)"
            if [[ "$count" -gt $MAX_COUNT ]]; then
                echo "ERROR: Couldn't synchronize clocks after $((count - 1)) attempts. Exiting"
                return 2
            fi

            echo "Attempt $count at restarting ptp and phc2sys services..."
            sudo systemctl daemon-reload
            sudo systemctl restart ptp4l@eth0.service phc2sys@eth0.service

            echo "Service restart complete. Waiting ${sleep_duration} seconds and then will reverify time status..."

            for i in $(seq 1 $sleep_duration); do
                printf "\r[%-${sleep_duration}s] %d/${sleep_duration}s %d%%" \
                    "$(head -c $i < /dev/zero | tr '\0' '-')" \
                    "$i" $(( i * 100 / sleep_duration ))
                sleep 1
            done
            echo
            ((count++))
            ret=1
        else
            echo "System and Hardware clocks are synchronized!"
            break
        fi
    done

    if [[ $ret -eq 1 ]]; then
        echo "Clock sync failed AT LEAST once. "
        echo "Resetting Jetson ptp, phc2shm, and chrony services..."

        ssh -o StrictHostKeyChecking=accept-new yride@$JETSON_STATIC_IP "bash -c 'source ~/yride_env_setup/custom_env.sh; restart_computer_ptp'" || { echo "SSH to Jetson failed"; }

        echo "Resetting services complete. "
        echo "Resetting ouster lidar ptp..."
        
        restart_all_ouster_ptp

        echo "Resetting lidar ptp complete."
    fi

    return "$ret"
}


# This condition is true if the script is executed, false if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo  "Script is being run directly, not sourced"
    
    source /home/yride/yride_env_setup/Sensors/sensor_ip.sh
    source /home/yride/yride_env_setup/Other/hostname_colors.sh
    source /home/yride/yride_env_setup/Sensors/restart_ouster_ptp.sh

    check_ptp_clocks
    var="$?"

    echo "returned: $var"

    if [[ $var -eq 0 ]]; then
        echo "✅ Clock sync OK"
    elif [[ $var -eq 1 ]]; then
        echo "Clock sync failed AT LEAST once. Need to reset Jetson and Ouster Lidars"
    elif [[ $var -eq 3 ]]; then
        echo "PPS is not being received. Check"
    elif [[ $var -eq 4 ]]; then
        echo "Clocks are synced but there is no PPS"
    else
        echo "❌ Clock sync FAILED"
    fi
fi
