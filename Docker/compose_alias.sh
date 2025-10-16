#!/bin/bash

DEBUG=false

# Allow xhost access to the container
# xhost +local:docker # run this in launch file instead and remove at end of launch file

COMPOSE_FILE=*compose.y*ml

# Function for compose up with timing
compose() (

    # Determine the base directory for the project name
    local project_base_dir=""
    if [[ $(basename "$PWD") == "docker" ]]; then
        # If currently in a 'docker' directory, use its parent as the project base
        project_base_dir=$(basename "$(dirname "$PWD")")
    else
        # Otherwise, use the current directory as the project base
        project_base_dir=$(basename "$PWD")
    fi

    # Sanitize the project_base_dir to meet Docker Compose naming requirements
    # 1. Convert to lowercase
    project_base_dir=$(echo "$project_base_dir" | tr '[:upper:]' '[:lower:]')
    # 2. Replace any character that is not a lowercase letter, number, hyphen, or underscore with a hyphen
    project_base_dir=$(echo "$project_base_dir" | sed -r 's/[^a-z0-9_-]+/-/g')
    # 3. Remove leading/trailing hyphens
    project_base_dir=$(echo "$project_base_dir" | sed -r 's/^-+|-+$//g')
    # 4. Ensure it starts with an alphanumeric character (if it somehow became empty or started with a hyphen)
    #    This step is mostly defensive; directory names usually start with valid characters.
    if [[ -z "$project_base_dir" || ! "$project_base_dir" =~ ^[a-z0-9] ]]; then
        project_base_dir="docker-project" # Fallback if sanitization results in an invalid name
    fi

    shopt -s nullglob
    
    # Check if there is more than one file matching the pattern
    local files=(${COMPOSE_FILE})
    local file_count=${#files[@]}

    if [ "$file_count" -gt 1 ]; then
        echo "Error: More than one file matches the pattern '${COMPOSE_FILE}'."
        return 1
    elif [ "$file_count" -eq 0 ]; then
        if [ "$DEBUG" = true ]; then
            echo "Warn: No file matches the pattern '${COMPOSE_FILE}'."
            echo "      Searching for docker directory..."
        fi
        if [ -d "docker" ]; then
            cd docker
            if [ "$DEBUG" = true ]; then
                echo "Found docker directory. Searching for compose file..."
            fi
            files=(${COMPOSE_FILE})
            file_count=${#files[@]}
            if [ "$file_count" -gt 1 ]; then
                echo "Error: More than one file matches the pattern '${COMPOSE_FILE}'."
                return 1
            elif [ "$file_count" -eq 0 ]; then
                echo "Error: No file matches the pattern '${COMPOSE_FILE}'."
                return 1
            else
                echo "Using file: 'docker/${files[0]}'"
            fi
        fi
    else
        # If exactly one file is found, print it and proceed with the compose command
        echo "Using file: '${files[0]}'"
    fi

    if [ "$DEBUG" = true ]; then
        echo "Project name is set to \"${project_base_dir}\""
    fi

    local compose_files=(-f "${files[0]}")
    local compose_file_basename="${files[0]%.*}"

    # Check if there is more than one file matching the pattern
    local extra_files=(${compose_file_basename}.*.y*ml)
    local extra_file_count=${#extra_files[@]}
    # echo "Extra files: ${extra_files[@]}"
    # echo "Extra file count: ${extra_file_count}"
    if [[ "${extra_file_count}" -gt 0 ]]; then
        for extra_file in "${extra_files[@]}"; do
            if [ -f "${extra_file}" ]; then
                check_for_device "$extra_file"
                missing_count=$?
                if [[ $missing_count -gt 0 ]]; then
                    echo "'${extra_file}' skipped due to $missing_count missing device(s)"
                    continue
                fi
                echo "'${extra_file}' found. Appending to compose file list"
                compose_files+=(-f "${extra_file}")
            fi
        done
    fi

    local interactive=0
    local compose_args=()

    # Process arguments
    for arg in "$@"; do
        if [ "$arg" == "-it" ]; then
            interactive=1
        else
            compose_args+=("$arg")
        fi
    done

    if [[ "${compose_args[0]}" == "up" ]]; then
        compose_args+=("-d")
    fi

    # Add the -p flag with the determined project name
    local project_name_flag="-p ${project_base_dir}"

    if $DEBUG ; then
        echo "Running: docker compose ${compose_files[*]} ${project_name_flag} ${compose_args[0]} ${compose_args[@]:1}"
    fi
    docker compose "${compose_files[@]}" ${project_name_flag} ${compose_args[0]} "${compose_args[@]:1}"
    if [[ "${compose_args[0]}" == "up" && "$interactive" -eq 1 ]]; then
        set_container_name "${files[0]}"
        docker exec -it $CONTAINER_NAME bash
        fi
)

check_for_device() {
    local file="$1"
    local missing=0

    # Extract device mappings from the compose file
    # Example line: - "/dev/ttyACM0:/dev/ttyACM0"
    local devices
    devices=$(grep -E '^\s*-\s*"/dev/' "$file" | sed -E 's/.*"(\/dev\/[^:]+).*/\1/')

    if [ -z "$devices" ]; then
        return 0
    fi

    for dev in $devices; do
        if [ ! -e "$dev" ]; then
            echo "⚠️  Device $dev listed in '$file' is not present on this system."
            missing=$((missing+1))
        fi
    done

    return $missing
}

set_container_name() {
    # Check if a Docker Compose file is provided
    if [ -z "$1" ]; then
        echo "Usage: $0 <docker-compose-file>"
        exit 1
    fi

    DOCKER_COMPOSE_FILE="$1"

    # Extract the container name using yq or grep/sed (prefer yq if available)
    if command -v yq &>/dev/null; then
        CONTAINER_NAME=$(yq '.services[] | .container_name' "$DOCKER_COMPOSE_FILE")
    else
        CONTAINER_NAME=$(grep 'container_name:' "$DOCKER_COMPOSE_FILE" | awk '{print $2}' | head -n 1)
    fi

    # Check if we got a container name
    if [ -z "$CONTAINER_NAME" ]; then
        echo "No container_name found in $DOCKER_COMPOSE_FILE"
        exit 1
    fi

    # Set the environment variable
    export CONTAINER_NAME="$CONTAINER_NAME"
    echo "CONTAINER_NAME is set to: $CONTAINER_NAME"

}

# Export the function so it's available in the current shell session
export -f compose
export -f set_container_name
export -f check_for_device