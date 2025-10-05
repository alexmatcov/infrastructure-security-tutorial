#!/bin/bash

if [ ! -f "/root/terraform-project/checkov-outputs.txt" ]; then
    exit 0
fi

exit 1