# Custom environment set up for yride golfcart
---
Original author: Ben Boyack 2025

## Use
Upon first install of this directory, run the `initial_setup.sh` script to add a source of the `custom_env.sh` file to your `.bashrc` file. 
Within the `custom_env.sh` file, add all files that need to be sourced to the `SCRIPTS_LIST` variable (Example is shown below). The paths should be relative to the location of the `custom_env.sh` file. This allows for a clean .bashrc file and quick integration of all custom commands to multiple computers and docker containers.

``` bash
# List of relative paths to .sh files to source
SCRIPTS_LIST=(
    "Docker/compose_alias.sh"
    "Ros2/ros2_build_clean.sh"
)
```