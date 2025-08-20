#!/bin/bash

rotation_matrix() (
    local SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    code ${SCRIPT_DIR}/rotation_matrix.ipynb
)