#!/bin/bash

rename_ros2_bag() {
    # 1. Validation & Input Handling
    if [ "$#" -ne 2 ]; then
        echo "Error: Missing arguments." >&2
        echo "Usage: rename_ros2_bag <old_bag_dir> <new_bag_name>" >&2
        return 1 2>/dev/null || exit 1
    fi

    local old_dir="${1%/}"  # Strip trailing slash if present
    local new_name="${2%/}"
    local parent_dir
    parent_dir=$(dirname "$old_dir")
    local new_dir="${parent_dir}/${new_name}"

    if [ ! -d "$old_dir" ]; then
        echo "Error: Directory '$old_dir' does not exist." >&2
        return 1 2>/dev/null || exit 1
    fi

    if [ -d "$new_dir" ]; then
        echo "Error: Target directory '$new_dir' already exists." >&2
        return 1 2>/dev/null || exit 1
    fi

    echo "Renaming ROS2 bag from '$old_dir' to '$new_dir'..."

    # Extract base name of old directory for pattern matching
    local old_name
    old_name=$(basename "$old_dir")

    # 2. Update metadata.yaml
    local metadata_file="${old_dir}/metadata.yaml"
    if [ -f "$metadata_file" ]; then
        # Replace occurrences of old name with new name (e.g. relative_file_paths, bag_name)
        sed -i "s/${old_name}/${new_name}/g" "$metadata_file"
        echo "  - Updated metadata.yaml"
    else
        echo "  - Warning: metadata.yaml not found inside '$old_dir'" >&2
    fi

    # 3. Rename .db3 files inside the directory
    for db_file in "${old_dir}"/*.db3; do
        if [ -f "$db_file" ]; then
            local filename
            filename=$(basename "$db_file")
            # Replace old bag name prefix with new name
            local new_filename="${filename//${old_name}/${new_name}}"
            if [ "$filename" != "$new_filename" ]; then
                mv "$db_file" "${old_dir}/${new_filename}"
                echo "  - Renamed file: $filename -> $new_filename"
            fi
        fi
    done

    # 4. Rename the directory itself
    mv "$old_dir" "$new_dir"
    echo "  - Renamed directory: $old_dir -> $new_dir"
    echo "Done! ROS2 bag successfully renamed to '$new_name'."
}

# If the script is executed directly (not sourced), run the function automatically
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    rename_ros2_bag "$@"
fi