#!/bin/bash

ccbi() {
    # pushd "$(dirname "$(realpath $0)")" > /dev/null

    clear

    local symlink_install=0
    local packages_select=()
    local option

    symlink_install=0
    packages_select=()
    OPTIND=1 # Reset in case getopts has been used previously in the shell.

    while getopts "sp:" option; do
        case "$option" in
        s)
            symlink_install=1
            ;;
        p)
            packages_select+=("$OPTARG")
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            return 1
            ;;
        esac
    done

    # Remove parsed options from the argument list
    shift $((OPTIND - 1))

    local colcon_cmd="colcon build"

    if [[ $symlink_install -eq 1 ]]; then
        colcon_cmd="$colcon_cmd --symlink-install"
    fi

    if [[ ${#packages_select[@]} -gt 0 ]]; then
        colcon_cmd="$colcon_cmd --packages-select ${packages_select[@]}"
    fi

    echo "Executing: $colcon_cmd $@" # Include any remaining non-option arguments
    eval "$colcon_cmd" "$@" # Execute the colcon command with all arguments
    if [[ $? -ne 0 ]]; then
        echo "Error: colcon build failed."
        return 1
    fi
    echo "Colcon build completed successfully."
    echo "Sourcing the workspace..."
    # Source the workspace
    source ./install/setup.bash

    # popd > /dev/null
}

colcon_clean() {
    rm -rf install/ build/ log/
    echo "Removed install/ build/ and log/"
}

export -f colcon_clean
export -f ccbi