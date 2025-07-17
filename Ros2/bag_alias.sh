#!/bin/bash

# Define environment variables for topics
export OUSTER_TOP_TOPICS="/ouster_top/points /ouster_top/imu /ouster_top/metadata"
export OUSTER_FRONT_TOPICS="/ouster_front/points /ouster_front/metadata"
export OUSTER_RIGHT_TOPICS="/ouster_right/points /ouster_right/metadata"
export OUSTER_LEFT_TOPICS="/ouster_left/points /ouster_left/metadata"
export OUSTER_BACK_TOPICS="/ouster_back/points /ouster_back/metadata"
export INERTIAL_SENSE_TOPICS="/inertial_sense/imu_raw /inertial_sense/imu /inertial_sense/odom_ins_ned /inertial_sense/gps1/NavSatFix /inertial_sense/RTK_cmp/rel"
export OTHER_TOPICS="/tf_static /tf"

# Function to display help message
show_help() {
    echo "Usage: record_bag [OPTIONS]"
    echo ""
    echo "Records ROS2 topics to a bag file."
    echo ""
    echo "Options:"
    echo "  -t                     Record Ouster Top topics ($OUSTER_TOP_TOPICS)"
    echo "  -l                     Record Ouster Left topics ($OUSTER_LEFT_TOPICS)"
    echo "  -r                     Record Ouster Right topics ($OUSTER_RIGHT_TOPICS)"
    echo "  -f                     Record Ouster Front topics ($OUSTER_FRONT_TOPICS)"
    echo "  -b                     Record Ouster Back topics ($OUSTER_BACK_TOPICS)"
    echo "  --all-topics           Record all currently advertised topics (equivalent to 'ros2 bag record -a')"
    echo "  --all-custom           Record all custom-defined topics (all Ouster, Inertial Sense, and Other topics)"
    echo "  -o <file_path>         Specify the output path for the bag file"
    echo "  -h, --help             Display this help message and exit"
    echo ""
    echo "Note: Inertial Sense topics ($INERTIAL_SENSE_TOPICS)"
    echo "      and Other topics ($OTHER_TOPICS)"
    echo "      are included by default when individual Ouster flags (-f, -r, -l, -t, -b) are used."
    echo "      They are also included with --all-custom."
}

# Function to record topics based on flags
record_bag() {
    local topics=()
    local output_path=""
    local all_topics_flag=false # Flag to indicate if --all-topics was used (ros2 bag record -a)
    local all_custom_flag=false # Flag to indicate if --all-custom was used (all defined topics)

    # Parse options using 'getopt' for both short and long options.
    # Added 'h' to short options and 'help' to long options.
    local parsed_options
    parsed_options=$(getopt -o frltbo:h --long all-topics,all-custom,help -n 'record_bag' -- "$@")

    # Check if getopt encountered any parsing errors.
    if [ $? -ne 0 ]; then
        echo "Error: Invalid arguments. Use -h or --help for usage information." >&2
        return 1
    fi

    # 'eval set -- "$parsed_options"' reassigns the shell's positional parameters
    # to the output of getopt, which reorders them so options are first.
    eval set -- "$parsed_options"

    # Loop through the parsed options and set flags or collect arguments.
    while true; do
        case "$1" in
            -f) # Front Ouster topics
                topics+=($OUSTER_FRONT_TOPICS)
                shift
                ;;
            -r) # Right Ouster topics
                topics+=($OUSTER_RIGHT_TOPICS)
                shift
                ;;
            -l) # Left Ouster topics
                topics+=($OUSTER_LEFT_TOPICS)
                shift
                ;;
            -t) # Top Ouster topics
                topics+=($OUSTER_TOP_TOPICS)
                shift
                ;;
            -b) # Back Ouster topics
                topics+=($OUSTER_BACK_TOPICS)
                shift
                ;;
            -o) # Output file path
                output_path="$2"
                shift 2 # Shift past the option and its argument
                ;;
            --all-topics) # Use 'ros2 bag record -a' directly
                all_topics_flag=true
                shift
                ;;
            --all-custom) # Record all custom-defined topics
                all_custom_flag=true
                shift
                ;;
            -h|--help) # Display help message
                show_help
                return 0 # Exit successfully after showing help
                ;;
            --) # End of options marker
                shift
                break
                ;;
            *) # Catch any unhandled internal errors from getopt
                echo "Internal error: Unhandled option '$1'" >&2
                return 1
                ;;
        esac
    done

    local command_args=() # Array to build the arguments for 'ros2 bag record'

    # Determine which set of topics to record based on the flags.
    if $all_topics_flag; then
        # If --all-topics is specified, we simply pass '-a' to ros2 bag.
        command_args+=("-a")
    elif $all_custom_flag; then
        # If --all-custom is specified, we explicitly list all defined topics.
        topics=($OUSTER_FRONT_TOPICS $OUSTER_RIGHT_TOPICS $OUSTER_LEFT_TOPICS $OUSTER_TOP_TOPICS $OUSTER_BACK_TOPICS $INERTIAL_SENSE_TOPICS $OTHER_TOPICS)
        command_args+=("${topics[@]}")
    else
        # If neither 'all' flag is used, add inertial_sense and other_topics
        # to the list of individually selected Ouster topics.
        topics+=($INERTIAL_SENSE_TOPICS)
        topics+=($OTHER_TOPICS)
        
        # If no topics were selected at all (either individually or via 'all' flags),
        # print the usage message.
        if [ ${#topics[@]} -eq 0 ]; then
            echo "Error: No topics selected for recording." >&2
            show_help # Show help if no topics are selected
            return 1
        fi
        command_args+=("${topics[@]}")
    fi

    # Add the output path argument if it was specified.
    if [ -n "$output_path" ]; then
        command_args+=("-o" "$output_path")
    fi

    # Construct the full 'ros2 bag record' command.
    local command="ros2 bag record ${command_args[@]}"
    
    echo "Executing: $command"
    
    # Execute the command. Using "${command_args[@]}" ensures proper word splitting
    # and quoting of arguments, preventing issues with spaces in topic names or paths.
    ros2 bag record "${command_args[@]}"

    # Copy log files if hostname is 'jetsonyride' ***
    if [ "$(hostname)" = "jetsonyride" ]; then
        echo "Copying log files..."

        local bag_folder=""
        if [ -n "$output_path" ]; then
            bag_folder="$output_path"
        else
            # If no output path was specified, ros2 bag record will create a folder
            # with a timestamp. We need to find the latest created bag folder.
            # This assumes that the script is run in the directory where bag files are created.
            bag_folder=$(ls -td | head -1)
            echo "No explicit output path given. Assuming bag folder is: $bag_folder"
        fi

        if [ -d "$bag_folder" ]; then
            echo "Copying /docker_yride/ros2_ws/src/log_ouster to $bag_folder..."
            cp -r /docker_yride/ros2_ws/scripts/log_ouster "$bag_folder/"

            echo "Copying /docker_yride/ros2_ws/src/log_emlid to $bag_folder..."
            cp -r /docker_yride/ros2_ws/src/log_emlid "$bag_folder/"

            echo "Copying log_imu from piyride to $bag_folder..."
            scp -r yride@192.168.68.40:/home/yride/imu_ros2_IS/log_imu "$bag_folder/"
            echo "Log file copying complete."
        else
            echo "Error: Bag folder '$bag_folder' not found. Cannot copy log files." >&2
        fi
    fi
}

# Export the function so it can be...
export -f record_bag
