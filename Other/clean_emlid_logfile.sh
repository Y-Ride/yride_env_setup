#!/bin/bash

clean_emlid_logfile(){

    if [[ -z "$1" ]]; then # If it doesn't exist or is empty
        echo "Usage: clean_emlid_logfile <path_to_logfile> <optional_output_path>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "ERROR: Input $1 is not a valid file."
        return 1
    fi

    local inputFile="$1"
 
    # Extract extension safely
    if [[ "$inputFile" == *.* ]]; then
        inputExt="${inputFile##*.}"
        inputBase="${inputFile%.*}"
    else
        inputExt="log"
        inputBase="$inputFile"
    fi

    if [[ $inputExt != "log" ]]; then
        echo "Input file \"$inputFile\" needs to be a .log file"
        return 1
    fi

    if [[ -n "$2" ]]; then # If it exists
        if [[ "$2" == *.* ]]; then
            outputFile="$2"
        else
            outputFile="$2.$inputExt"
        fi
    else
        outputFile="cleaned_${inputBase}.$inputExt"
    fi

    echo "Removing \"Bad address\" lines from ${inputFile}. Output to ${outputFile}"

    # Source - https://stackoverflow.com/a
    # Posted by SiegeX, modified by community. See post 'Timeline' for change history
    # Retrieved 2025-12-18, License - CC BY-SA 4.0

    # sed '/Bad address/d' "$inputFile" > "$outputFile"

    awk '
    BEGIN { IGNORECASE=1; skip=0 }
    {
        if ($0 ~ /Bad address/) {
            if (skip == 0) {
                print      # print the first Bad address line
                skip = 1   # mark to skip the following consecutive ones
            }
            # else do nothing (skip)
        } else {
            print          # print non-Bad address lines
            skip = 0       # reset skip when we hit a non-Bad address line
        }
    }
    ' "$inputFile" > "$outputFile"

}