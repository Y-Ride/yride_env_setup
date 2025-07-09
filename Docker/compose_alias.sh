#!/bin/bash

# Allow xhost access to the container
# xhost +local:docker # run this in launch file instead and remove at end of launch file

COMPOSE_FILE=*compose.yaml

# Function for compose up with timing
compose() {
    local original_dir=$(pwd)

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

    
    # Check if there is more than one file matching the pattern
    local files=($(ls ${COMPOSE_FILE} 2>/dev/null))
    local file_count=${#files[@]}

    if [ "$file_count" -gt 1 ]; then
        echo "Error: More than one file matches the pattern ${COMPOSE_FILE}."
        return 1
    elif [ "$file_count" -eq 0 ]; then
        echo "Warn: No file matches the pattern ${COMPOSE_FILE}."
        echo "      Searching for docker directory..."
        if [ -d "docker" ]; then
            cd docker
            echo "Found docker directory. Searching for compose file..."
            files=($(ls ${COMPOSE_FILE} 2>/dev/null))
            file_count=${#files[@]}
            if [ "$file_count" -gt 1 ]; then
                echo "Error: More than one file matches the pattern ${COMPOSE_FILE}."
                return 1
            elif [ "$file_count" -eq 0 ]; then
                echo "Error: No file matches the pattern ${COMPOSE_FILE}."
                return 1
            else
                echo "Using file: docker/${files[0]}"
            fi
        fi
    else
        # If exactly one file is found, print it and proceed with the compose command
        echo "Using file: ${files[0]}"
    fi

    echo "Project name will be set to \"${project_base_dir}\""

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

    # Add the -p flag with the determined project name
    local project_name_flag="-p ${project_base_dir}"

    if [ "${compose_args[0]}" == "up" ]; then
        docker compose -f "${files[0]}" ${project_name_flag} up -d "${compose_args[@]:1}"
        if [ "$interactive" -eq 1 ]; then
            set_container_name "${files[0]}"
            docker exec -it $CONTAINER_NAME bash
        fi
    elif [ "${compose_args[0]}" == "down" ]; then
        docker compose -f "${files[0]}" ${project_name_flag} down "${compose_args[@]:1}"
    else
        echo "Invalid option. Use 'compose up' or 'compose down'."
    fi

    cd "$original_dir" # Always go back to the original directory
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

    # # Optionally, save it to your shell environment
    # echo "export CONTAINER_NAME=$CONTAINER_NAME" >> ~/.bashrc

}

# Export the function so it's available in the current shell session
export -f compose
export -f set_container_name
