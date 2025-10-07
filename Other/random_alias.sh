#!/bin/bash

chownme() {
    local target="${1:-$(pwd)}"
    echo "Running: sudo chown -R $(whoami):$(whoami) $target"
    sudo chown -R "$(whoami):$(whoami)" "$target"
}

alias c='clear'
alias findlidar='avahi-browse -lrt _roger._tcp'

if [ "$SSH_CONNECTION" ]; then
    clear
fi

if [[ $HOSTNAME = "jetsonyride" ]]; then
    # nvidia-smi doesn't work with integrated gpus
    # Instead this uses a community python package
    # Download with this 'sudo pip3 install jetson-stats' and then reboot
    alias nvidia-smi="echo \"Running 'jtop'\" && jtop"
fi

# Set tab completion to be case insensitive
if [[ $- == *i* ]]; then # Check to see if stdin is connected to a terminal
    bind 'set completion-ignore-case on'
fi