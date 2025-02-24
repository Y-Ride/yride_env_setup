#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of relative paths to .sh files to source
SCRIPTS_LIST=(
    "Docker/compose_alias.sh"
    "Ros2/ros2_build_clean.sh"
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