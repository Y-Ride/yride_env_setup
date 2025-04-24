#!/bin/bash

alias chownme='sudo chown -R $(whoami) $(pwd)'
alias c='clear'
alias findlidar='avahi-browse -lrt _roger._tcp'

if [ "$SSH_CONNECTION" ]; then
    clear
fi