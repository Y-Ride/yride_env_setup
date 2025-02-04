#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the custom_env.sh file
CUSTOM_ENV="$SCRIPT_DIR/custom_env.sh"

# Path to the .bashrc file
BASHRC="$HOME/.bashrc"

# Check if custom_env.sh exists
if [[ ! -f "$CUSTOM_ENV" ]]; then
    echo "Error: custom_env.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Check if the source line is already in .bashrc
if grep -qxF "source \"$CUSTOM_ENV\"" "$BASHRC"; then
    echo "custom_env.sh is already sourced in .bashrc"
    exit 0
fi

# Append the source command to .bashrc
echo -e "\nsource \"$CUSTOM_ENV\"" >> "$BASHRC"

# Confirm success
echo "Added source command for custom_env.sh to .bashrc"
