#!/bin/bash

header() {
    ros2 topic echo --field header "$@"
}

timestamp() {
    ros2 topic echo --field header.stamp "$@"
}

frame_id() {
    ros2 topic echo --field header.frame_id "$@"
}

_ros2_topic_list_autofill() {
    local cur
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    local topics
    topics=$(ros2 topic list 2>/dev/null)
    COMPREPLY=( $(compgen -W "${topics}" -- ${cur}) )
    return 0
}

complete -F _ros2_topic_list_autofill header
complete -F _ros2_topic_list_autofill timestamp
complete -F _ros2_topic_list_autofill frame_id
