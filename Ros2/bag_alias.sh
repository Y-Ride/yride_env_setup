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
    echo "  --other-only           Record all topic specified in INERTIAL_SENSE_TOPICS and OTHER_TOPICS"
    echo "  -o <file_path>         Specify the output path for the bag file"
    echo "  --no-topic-monitor     Disable topic synchronization check before playing the bag"
    echo "  -h, --help             Display this help message and exit"
    echo ""
    echo "Note: INERTIAL_SENSE_TOPICS ($INERTIAL_SENSE_TOPICS)"
    echo "      and OTHER_TOPICS ($OTHER_TOPICS)"
    echo "      are included by default when individual Ouster flags (-f, -r, -l, -t, -b) are used."
    echo "      They are also included with --all-custom and --other-only."
}

# Function to record topics based on flags
record_bag() {
    local topics=()
    local output_path=""
    local all_topics_flag=false # Flag to indicate if --all-topics was used (ros2 bag record -a)
    local all_custom_flag=false # Flag to indicate if --all-custom was used (all defined topics)
    local other_only_flag=false # Flag to indicate if --other-only was used
    local topic_monitor_flag=true # Flag to indicate to check for topic synchronization
    local custom_name_flag=false

    # Parse options using 'getopt' for both short and long options.
    # Added 'h' to short options and 'help' to long options.
    local parsed_options
    parsed_options=$(getopt -o frltbo:h --long all-topics,all-custom,other-only,no-topic-monitor,help -n 'record_bag' -- "$@")

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
                custom_name_flag=true
                ;;
            --all-topics) # Use 'ros2 bag record -a' directly
                all_topics_flag=true
                shift
                ;;
            --all-custom) # Record all custom-defined topics
                all_custom_flag=true
                shift
                ;;
            --other-only) # Only topics in INERTIAL_SENSE_TOPICS and OTHER_TOPICS
                other_only_flag=true
                shift
                ;;
            --no-topic-monitor) # Disable the topic monitoring for when not running on golfcart
                topic_monitor_flag=false
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
    elif $other_only_flag; then
        # If --other-ony is specified, we only include the 'other' and 'inertial sense' topics.
        topics=($INERTIAL_SENSE_TOPICS)
        topics+=($OTHER_TOPICS)
        command_args+=("${topics[@]}")
    else
        # If no topics were selected at all (either individually or via 'all' flags),
        # print the usage message.
        if [ ${#topics[@]} -eq 0 ]; then
            echo "Error: No topics selected for recording." >&2
            show_help # Show help if no topics are selected
            return 1
        fi

        # If neither 'all' flag is used, add inertial_sense and other_topics
        # to the list of individually selected Ouster topics.
        topics=($INERTIAL_SENSE_TOPICS)
        topics+=($OTHER_TOPICS)

        command_args+=("${topics[@]}")
    fi

    # Add the output path argument if it was specified.
    if [ -n "$output_path" ]; then
        command_args+=("-o" "$output_path")
    else
        output_path=$(get_bag_name)
        echo "Using automated bag name: $output_path"
        command_args+=("-o" "$output_path")
    fi

    if $topic_monitor_flag; then 
        ros2 run topic_monitor topic_monitor_node

        # After the node finishes, ask the user whether to continue
        read -p "Do you want to continue? [Y/n]: " user_input
        user_input=${user_input:-y}  # Default to 'y' if empty

        # Convert input to lowercase
        user_input=$(echo "$user_input" | tr '[:upper:]' '[:lower:]')

        if [[ "$user_input" == "n" || "$user_input" == "no" ]]; then
            echo "Exiting script."
            return 0
        fi
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

        # Copy log files to bag folder
        local log_ouster_folder="/root/ros2_ws/scripts/log_ouster"
        local log_emlid_folder="/root/ros2_ws/src/emlid_gps/log_emlid"
        local log_imu_folder="/home/yride/imu_ros2_IS/log_imu"

        if [ -d "$bag_folder" ]; then
            echo "Copying $log_ouster_folder to $bag_folder..."
            if ! cp -r "$log_ouster_folder" "$bag_folder/"; then
                echo -e "\e[31mERROR:\e[0m Didn't copy $log_ouster_folder correctly"
            fi

            echo "Copying $log_emlid_folder to $bag_folder..."
            if ! cp -r "$log_emlid_folder" "$bag_folder/"; then
                echo -e "\e[31mERROR:\e[0m Didn't copy $log_emlid_folder correctly"
            fi

            echo "Copying log_imu from piyride to $bag_folder..."
            if ! sshpass -p "${PI_PASS}" scp -o StrictHostKeyChecking=no -r yride@192.168.68.40:"$log_imu_folder" "$bag_folder/"; then
                echo -e "\e[31mERROR:\e[0m Didn't copy $log_imu_folder correctly from piyride"
            fi

            echo "Log file copying complete."
        else
            echo "Error: Bag folder '$bag_folder' not found. Cannot copy log files." >&2
        fi

        # Update field test table
        if [ "$custom_name_flag" = false ]; then
            read -p "Do you want to add a row to the field test table? [y]/n: " add_row_choice
            add_row_choice=${add_row_choice:-y}  # default to 'y' if user just presses enter

            if [ "$add_row_choice" = "y" ] || [ "$add_row_choice" = "Y" ]; then
                local field_test_table_path="/root/golf_cart/log-+-notes.md"
                echo "Recording completed. Adding entry to $field_test_table_path"

                # Extract date and time
                local bag_date=$(echo "$bag_folder" | awk -F'__' '{print $1}')   # "8_25_2025"
                local bag_time=$(echo "$bag_folder" | awk -F'__' '{print $2}')  # "1114"

                # Split date
                local month=$(echo "$bag_date" | cut -d'_' -f1)
                local day=$(echo "$bag_date" | cut -d'_' -f2)
                local year=$(echo "$bag_date" | cut -d'_' -f3)

                # Split time (first 2 chars = hour, last 2 chars = minute)
                local hour=${bag_time:0:2}
                local minute=${bag_time:2:2}
                
                local date_time_entry="${month}/${day}/${year}<br>${hour}:${minute}"
                echo "bag_date: $bag_date, bag_time: $bag_time, month: $month, day: $day, year: $year, hour: $hour, minute: $minute"

                # Get user input for Location and Notes
                echo "Enter information for the following columns:"
                read -p "Location: " location_entry
                read -p "Notes: " notes_entry
                
                # Create the new table row
                local new_row="<tr><td>${date_time_entry}</td><td>${location_entry}</td><td>${notes_entry}</td></tr>"

                # Use sed to insert the new row before the </tbody> tag
                # sed -i "/<\/tbody><\/table>/i$new_row" $field_test_table_path
                sed -i "s|</tbody></table>|${new_row}&|" "$field_test_table_path"
                echo "Log entry added successfully."
            else
                echo "Skipping field test table entry."
            fi
        else
            echo "Manual name used. Skipping automated log entry."
        fi
    fi
}

# Function to get a formatted timestamp rounded to the nearest 5 minutes
# get_bag_name() {
#     local date_time=$(date +"%_m/%_d/%_y")
#     local hour=$(date +"%H")
#     local minute=$(date +"%M")
    
#     # Calculate the rounded minute
#     local rounded_minute=$(( (minute + 2) / 5 * 5 ))
#     if [ "$rounded_minute" -eq 60 ]; then
#         rounded_minute=0
#         # Increment hour if minutes roll over
#         hour=$((hour + 1))
#     fi
#     local formatted_minute=$(printf "%02d" $rounded_minute)

#     # Re-calculate date and hour in case of rollover
#     if [ "$hour" -eq 24 ]; then
#         hour=0
#         date_time=$(date -d "tomorrow" +"%_m/%_d/%_y")
#     fi
#     local formatted_hour=$(printf "%02d" $hour)

#     local month=$(echo $date_time | cut -d'/' -f1)
#     local day=$(echo $date_time | cut -d'/' -f2)
#     local year=$(echo $date_time | cut -d'/' -f3)

#     echo "${month}_${day}_${year}__${formatted_hour}${formatted_minute}"
# }

get_bag_name() {
    # Set the timezone to Mountain Daylight Time (MDT)
    local TZ='America/Denver'
    
    # Get the current time in seconds since the epoch in the specified timezone
    local current_seconds=$(TZ="$TZ" date +%s)
    
    # Calculate the rounded time to the nearest 5 minutes
    local rounded_seconds=$(( (current_seconds + 150) / 300 * 300 ))
    
    # Format the rounded timestamp to the desired string, using '-' to remove padding
    local formatted_time=$(TZ="$TZ" date -d "@$rounded_seconds" +"%-m_%-d_%Y__%H%M")
    
    echo "$formatted_time"
}

_record_bag() {
    local cur prev opts base
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    
    # Define the options that your script accepts
    opts="-t -l -r -f -b --all-topics --all-custom --other-only -o --no-topic-monitor -h --help"

    # Handle completion for options
    if [[ "$cur" == -* ]]; then
        COMPREPLY=( $(compgen -W "${opts}" -- "${cur}") )
        return 0
    fi

    # Handle completion for the argument of the -o option
    if [[ "$prev" == "-o" || "$prev" == "-n" || "$prev" == "--name" ]]; then
        _filedir
        return 0
    fi

    # Default completion (e.g., if no specific completion is defined for an argument)
    COMPREPLY=( $(compgen -f -- "${cur}") )
}


# Export the function so it can be...
export -f record_bag
complete -F _record_bag record_bag
