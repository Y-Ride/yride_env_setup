#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of relative paths to .sh files to source
SCRIPTS_LIST=(
    "Docker/compose_alias.sh"
    "Docker/interactive_terminal_alias.sh"
    "Other/hostname_colors.sh"
    "Other/random_alias.sh"
    "Other/rotation_matrix.sh"
    "PCD/pcd_tools.sh"
    "Ros2/bag_alias.sh"
    "Ros2/echo_header_info.sh"
    "Ros2/ros2_build_clean.sh"
    "Sensors/restart_ouster_ptp.sh"
    "Sensors/sensor_ip.sh"
)

# Loop through the list and source each script
for script in "${SCRIPTS_LIST[@]}"; do
    SCRIPT_PATH="$SCRIPT_DIR/$script"
    if [[ -f "$SCRIPT_PATH" ]]; then
        source "$SCRIPT_PATH"
        # echo "sourcing $SCRIPT_PATH"
    else
        echo "Warning: $SCRIPT_PATH not found. Skipping."
    fi
done
