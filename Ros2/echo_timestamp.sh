#!/bin/bash

timestamp() {
    ros2 topic echo --field header.stamp "$@"
}

_timestamp_complete() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    local topics
    topics=$(ros2 topic list 2>/dev/null)
    COMPREPLY=( $(compgen -W "${topics}" -- ${cur}) )
    return 0
}

complete -F _timestamp_complete timestamp
