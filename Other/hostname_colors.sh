#!/bin/bash

## Color    Foreground	Background
# Black	    30	        40
# Red	    31	        41
# Green	    32	        42
# Yellow	33	        43
# Blue	    34	        44
# Magenta	35	        45
# Cyan	    36	        46
# White	    37	        47


HOST_NAME_COLOR=32 # Green default
if [ "$HOSTNAME" = "piyride" ]; then
    HOST_NAME_COLOR=31 # Red
elif [ "$HOSTNAME" = "jetsonyride" ]; then
    HOST_NAME_COLOR=33 # Yellow
fi

FIRST_NAME=$USER
if [ "$FIRST_NAME" = "benboyack" ]; then
    FIRST_NAME="beast"
fi

if [ -z "${CONTAINER_NAME}" ]; then
    CONTAINER_NAME="\u"
fi

if [ -f "/.dockerenv" ]; then
    echo "Running in a Docker container. Changing user prompt color..."
    # PS1='${debian_chroot:+($debian_chroot)}\[\033[01;37m;36m\]\u@\h\[\033[01;${HOSTNAME}m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
    PS1="\[\e[0;37m\]${CONTAINER_NAME}\[\e[32m\]@\[\e[${HOST_NAME_COLOR}m\]\h:\[\e[0m\]\[\e[0;36m\]\w\$ \[\e[0m\]"
else
    PS1="\[\e[1;32m\]${FIRST_NAME}@\[\e[1;${HOST_NAME_COLOR}m\]\h:\[\e[1;34m\]\w\$ \[\e[0m\]"
fi
