# Scripts to help run ros2 / make it easier to run certain commands

This document provides a list of the files located in this folder with their respective descriptions.

## Files and Descriptions

**ros2_build_clean.sh:**

- `ccbi` stands for clear, colcon build, install. This alias runs the following code with any flags passed to the colcon build step
    ``` bash
    clear
    colcon build <flags>
    source install/setup.bash
    ```

- `colcon_clean` removes the `/build`, `/install`, and `/log` folders from the directory in which this command is called.