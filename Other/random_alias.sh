#!/bin/bash

alias chownme='sudo chown -R $(whoami):$(whoami) $(pwd)'
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