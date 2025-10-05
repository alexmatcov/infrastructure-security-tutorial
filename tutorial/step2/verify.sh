#!/bin/bash

# Direct file check
if [ -f "/root/.local/bin/checkov" ]; then
    exit 0
fi

exit 1