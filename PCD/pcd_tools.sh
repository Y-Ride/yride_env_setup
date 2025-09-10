#!/bin/bash

pcd()(
    
    local SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    local VIZ_FILE="${SCRIPT_DIR}/pcd_visualization.py"
    local OUTLIER_FILE="${SCRIPT_DIR}/pcd_outlier_removal.py"
    local pcd_opt=""
    local pcd_path=""

    ### Parse arguments
    if [[ -z "$1" || -z "$2" ]]; then
        echo "Usage: pcd <-v|-o> <path_to_pcd_file.pcd>"
        return 1
    fi
    pcd_opt="$1"
    pcd_path="$2"

    ### Activate python virtual environment
    source "${SCRIPT_DIR}/.venv/bin/activate"

    ### Run respective python files 
    case "${pcd_opt}" in
        -v)
            if check_if_pcd $pcd_path ; then
                echo "Running: python ${VIZ_FILE} ${pcd_path}"
                python "${VIZ_FILE}" "${pcd_path}"
            fi
            ;;
        -o)
            if check_if_pcd $pcd_path ; then
                echo "Running: python ${OUTLIER_FILE} ${pcd_path}"
                python "${OUTLIER_FILE}" "${pcd_path}"
            fi
            ;;
        *)
            echo "Invalid option: Must be either '-v' for pcd_visualization.py or"
            echo "                or '-o' for pcd_outlier_removal.py"
            return 1
            ;;
    esac

)

check_if_pcd(){
    local path="$1"
    if [[ -f $path && $path == *.pcd ]]; then
        # echo "${path} is a valid .pcd file"
        return 0
    else 
        echo "${path} is NOT a valid .pcd file. Please fix."
        return 1
    fi
}
