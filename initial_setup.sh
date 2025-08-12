#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Path to the custom_env.sh file
CUSTOM_ENV="$SCRIPT_DIR/custom_env.sh"

# Path to the .bashrc file
BASHRC="${HOME}/.bashrc"

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

# Set up needed virtual python environment
echo "Setting up python3 virtual environment for pcd visualization..."
echo "Running 'sudo apt install python3-venv -y'. Need sudo permissions."
sudo apt install python3-venv -y 
python3 -m venv "${SCRIPT_DIR}/PCD/.venv"
if [[ ! -f "${SCRIPT_DIR}/PCD/.venv/bin/activate" ]]; then
    echo "Error: virtual environment creation failed."
    exit 1
fi
source "${SCRIPT_DIR}/PCD/.venv/bin/activate"
pip install open3d
deactivate

# Confirm success
echo "Added source command for custom_env.sh to .bashrc"
echo "Run 'source ~/.bashrc' or restart your terminal to apply changes"
