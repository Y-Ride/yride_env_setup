# Function to launch interactive terminal inside a container
cit() {
    docker exec -it "$1" /bin/bash
}

# Auto-complete function for cit
_cit_autocomplete() {
    local curr_word="${COMP_WORDS[COMP_CWORD]}"
    local containers=$(docker ps --format '{{.Names}}')
    COMPREPLY=($(compgen -W "$containers" -- "$curr_word"))
}

# Register the autocomplete function
complete -F _cit_autocomplete cit

