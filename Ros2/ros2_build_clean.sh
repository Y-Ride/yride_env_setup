#!/bin/bash

ccbi() {
    local symlink_install=1
    local packages_select=()
    local option
    local no_clear_flag=false

    OPTIND=1 # Reset getopts index

    while getopts "sp:n" option; do
        case "$option" in
        s)
            symlink_install=0
            ;;
        p)
            packages_select+=("$OPTARG")
            ;;
        n)
            no_clear_flag=true
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            return 1
            ;;
        esac
    done

    # Remove parsed options from the argument list
    shift $((OPTIND - 1))

    # Separate positional packages (not starting with - or --)
    # and forward other args (options) to colcon
    local colcon_args=()
    for arg in "$@"; do
        if [[ "$arg" != -* ]]; then
            packages_select+=("$arg")
        else
            colcon_args+=("$arg")
        fi
    done

    # Clear screen unless -n was given
    if ! $no_clear_flag; then
        clear
    fi

    local colcon_cmd="colcon build"

    if [[ $symlink_install -eq 1 ]]; then
        colcon_cmd+=" --symlink-install"
    fi

    if [[ ${#packages_select[@]} -gt 0 ]]; then
        colcon_cmd+=" --packages-select ${packages_select[*]}"
    fi

    echo "Executing: $colcon_cmd ${colcon_args[*]}"
    eval "$colcon_cmd" "${colcon_args[@]}"
    if [[ $? -ne 0 ]]; then
        echo "Error: colcon build failed."
        return 1
    fi

    echo "Colcon build completed successfully."
    echo "Sourcing the workspace..."
    source ./install/setup.bash
}


colcon_clean() {
    rm -rf install/ build/ log/
    echo "Removed install/ build/ and log/"
}

export -f colcon_clean
export -f ccbi