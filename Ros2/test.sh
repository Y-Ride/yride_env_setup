#!/bin/bash

test() (

    local bag_folder="/root/ros2_ws/bags/longterm_mapping/$1"

    local bag_size="N/A"
    local bag_duration="N/A"
    if [ -d "$bag_folder" ]; then
        bag_size=$(ros2 bag info "$bag_folder" 2>/dev/null | awk -F': ' '/Bag size/ {gsub(/^ +/, "", $2); sub(/ GiB$/, "", $2); print $2; exit}')
        bag_duration=$(ros2 bag info "$bag_folder" 2>/dev/null | awk -F': ' '/Duration/ {gsub(/^ +/, "", $2); sub(/s$/, "", $2); printf "%.1f\n", $2; exit}')
    fi

    echo "<td>$bag_size</td><td>$bag_duration</td>"
)

# If the script is being executed (not sourced), call the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    test "$@"
fi

