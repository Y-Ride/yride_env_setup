#!/bin/bash

# Get dates for each sensor and computer to see if they are syncronized

check_lidar_timesync() 
{
    # LIDAR_TOP_TIME=$(curl -s -X GET http://192.168.68.50/api/v1/time | jq -r '.system.realtime' | xargs -I {} date -d @{} +"%s.%N")
    LIDAR_TOP_TIME=$(curl -s -X GET http://${LIDAR_STATIC_IP_TOP}/api/v1/time | jq -r '.sensor.timestamp.time')
    TOP_DIFF=$(echo "$LIDAR_TOP_TIME - $(date +%s.%N)" | bc)

    LIDAR_LEFT_TIME=$(curl -s -X GET http://${LIDAR_STATIC_IP_LEFT}/api/v1/time | jq -r '.sensor.timestamp.time')
    LEFT_DIFF=$(echo "$LIDAR_LEFT_TIME - $(date +%s.%N)" | bc)

    LIDAR_RIGHT_TIME=$(curl -s -X GET http://${LIDAR_STATIC_IP_RIGHT}/api/v1/time | jq -r '.sensor.timestamp.time')
    RIGHT_DIFF=$(echo "$LIDAR_RIGHT_TIME - $(date +%s.%N)" | bc)

    LIDAR_FRONT_TIME=$(curl -s -X GET http://${LIDAR_STATIC_IP_FRONT}/api/v1/time | jq -r '.sensor.timestamp.time')
    FRONT_DIFF=$(echo "$LIDAR_FRONT_TIME - $(date +%s.%N)" | bc)

    LIDAR_BACK_TIME=$(curl -s -X GET http://${LIDAR_STATIC_IP_BACK}/api/v1/time | jq -r '.sensor.timestamp.time')
    BACK_DIFF=$(echo "$LIDAR_BACK_TIME - $(date +%s.%N)" | bc)

    HOST_TIME=$(date +%s.%N)
    HOST_HUMAN_TIME=$(date)

    # Print the results
    echo "Top:    ${LIDAR_TOP_TIME}, diff from $HOSTNAME: ${TOP_DIFF}"; \
    echo "Left:   ${LIDAR_LEFT_TIME}, diff from $HOSTNAME: ${LEFT_DIFF}"; \
    echo "Right:  ${LIDAR_RIGHT_TIME}, diff from $HOSTNAME: ${RIGHT_DIFF}"; \
    echo "Front:  ${LIDAR_FRONT_TIME}, diff from $HOSTNAME: ${FRONT_DIFF}"; \
    echo "Back:   ${LIDAR_BACK_TIME}, diff from $HOSTNAME: ${BACK_DIFF}"; \
    echo "$HOSTNAME:  ${HOST_TIME} -> ${HOST_HUMAN_TIME}"
    echo ""

}

check_computer_timesync()
{

    if [[ $HOSTNAME == $JETSON_HOSTNAME ]]; then
        local other_hostname=$PI_HOSTNAME
        local other_ip=$PI_STATIC_IP
    elif [[ $HOSTNAME == $PI_HOSTNAME ]]; then
        local other_hostname=$JETSON_HOSTNAME
        local other_ip=$JETSON_STATIC_IP
    fi

    OTHER_TIME=$(ssh ${other_ip} 'date +%s.%N')
    OTHER_DIFF=$(echo "$OTHER_TIME - $(date +%s.%N)" | bc)

    HOST_TIME=$(date +%s.%N)
    HOST_HUMAN_TIME=$(date)

    echo "$other_hostname: ${OTHER_TIME}, diff from $HOSTNAME: ${OTHER_DIFF}"; \
    echo "$HOSTNAME:  ${HOST_TIME} -> ${HOST_HUMAN_TIME}"
    echo ""

}

check_timesync()
{
    check_lidar_timesync
    check_computer_timesync

    chronyc sources
}

# This condition is true if the script is executed, false if sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_timesync
fi
