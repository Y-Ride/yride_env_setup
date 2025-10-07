#!/bin/bash

check_ptp_clocks_return_key() {
    echo "Key for check_ptp_clock return:"
    echo "  0 -> Clocks were already synchronized"
    echo "  1 -> Clocks were not synchronized but now they are"
    echo "  2 -> Error: Clocks are not synchronized"
    echo "  3 -> PPS is not being read from GPS"
    echo "  4 -> No static IP connection to $PI_HOSTNAME"
}

check_ptp_clocks()
(
    if [[ $HOSTNAME != $PI_HOSTNAME ]]; then
        echo "Connecting to $PI_HOSTNAME via SSH..."
        ssh yride@$PI_STATIC_IP "bash -lc 'check_ptp_clocks'" || { echo "SSH connection failed."; return 4; }
        return $?
    fi

    local count=1
    local ret=0
    active_source=$(chronyc sources | awk '/^\#*\*/ {print $2}')

    if [[ "$active_source" == "PPS" ]]; then
        echo "✅ PPS is active"
    else
        ret=3
        echo "❌ PPS is NOT active. Either no GPS is being received or there is another issue."
        read -p "Proceed? [y/N]: " answer
        answer=${answer:-n}

        if [[ $answer != [Yy] ]]; then
            echo "Cancelled."
            return $ret
        fi
            
    fi

    THRESHOLD=37.0 # seconds
    sleep_duration=20

    
    while true; do
        

        phc_time=$(sudo phc_ctl /dev/ptp0 get | awk '/clock time/ {print $5}')
        sys_time=$(date +%s.%N)

        diff=$(echo "$phc_time - $sys_time" | bc -l)
        echo "PHC - System = $diff seconds"
        # local offset=$(sudo phc_ctl /dev/ptp0 cmp | awk '{gsub(/ns$/,"",$NF); print $NF}')
        offset=$(echo "$diff" | awk '{if($1<0) $1=-$1; print $1}')

        if (( $(echo "$offset > $THRESHOLD" | bc -l) )); then
            echo "Offset too large! (threshold is $THRESHOLD)"
            if [[ "$count" -gt 5 ]]; then
                echo "ERROR: Couldn't synchronize clocks after $((count -1)) attepts. Exiting"
                return 2
            fi
            echo "Attempt $count at restarting ptp and phc2sys services..."
            sudo systemctl daemon-reload
            sudo systemctl restart ptp4l@eth0.service phc2sys@eth0.service

            echo "Service restart complete. Waiting ${sleep_duration} seconds and then will reverify time status..."

            for i in $(seq 1 $sleep_duration); do
                # Print progress bar
                printf "\r[%-${sleep_duration}s] %d/${sleep_duration}s %d%%" "$(head -c $i < /dev/zero | tr '\0' '-')" ${i} $(( i * 100 / sleep_duration ))
                sleep 1
            done
            echo # move to new line after loop
            ((count++))
            ret=1
            # THRESHOLD=37.0
        else
            echo "System and Hardware clocks are synchronized!"
            echo "Offset is $offset ns"
            break
        fi
    done
    return "$ret"
)


# This condition is true if the script is executed, false if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly, not sourced
    check_ptp_clocks
    var=$?

    echo "var = $var"

    if [[ $var -eq 0 ]]; then
        echo "✅ Clock sync OK"
    elif [[ $var -eq 1 ]]; then
        echo "Clock sync failed AT LEAST once. Need to reset Jetson and Ouster Lidars"
    elif [[ $var -eq 3 ]]; then
        echo "PPS is not being received. Check"
    else
        echo "❌ Clock sync FAILED"
    fi
fi
