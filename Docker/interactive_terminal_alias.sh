# Function to launch interactive terminal inside a container
cit() {
    local container_name="$1"
    local clear_terminal=true

    # Check for the --no-clear flag
    if [[ "$2" == "--no-clear" ]]; then
        clear_terminal=false
    fi

    # Clear the terminal if the flag is not present
    if "$clear_terminal"; then
        clear
    fi

    # Execute the docker command
    docker exec -it "$container_name" /bin/bash
}

# Auto-complete function for cit
_cit_autocomplete() {
    local curr_word="${COMP_WORDS[COMP_CWORD]}"
    local prev_word="${COMP_WORDS[COMP_CWORD-1]}"
    local containers=$(docker ps --format '{{.Names}}')
    local options="--no-clear"

    if [[ "$COMP_CWORD" -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$containers" -- "$curr_word"))
    elif [[ "$COMP_CWORD" -eq 2 ]] && [[ "$prev_word" != "--no-clear" ]]; then
        COMPREPLY=($(compgen -W "$options" -- "$curr_word"))
    fi
}

# Register the autocomplete function
complete -F _cit_autocomplete cit