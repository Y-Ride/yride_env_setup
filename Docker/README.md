# Scripts to help run docker / make it easier to run certain commands

This document provides a list of the files located in this folder with their respective descriptions.

## Files and Descriptions

**compose_alias.sh:**

This file makes it easier to run `docker compose ...`. It provides funtionality to run `compose up ...` and `compose down`.

- `compose up` finds the docker compose file that is located in the location where the command is ran. It searches for any file that ends with `compose.yaml` and uses that file as the `-f` flag of the normal `docker compose up -f ` command. 
    - It also automatically adds the `-d` command to make the command run in the background.
    - I added an additional flag of `-it` (which docker compose doesn't natively do) which finds the container name and launches the `docker exec -it <container_name> bash` to open an interactive terminal.
    > Note that the container name must be set in the docker compose file. For example `container_name: yride_all_together`

- `compose down` just runs `docker compose down`