#!/bin/bash

# Check if the output file exists
if [ ! -f "/root/terraform-project/checkov-outputs2.txt" ]; then
    exit 1
fi

# Check if the file contains "Failed checks: 0"
if grep -q "Failed checks: 0" /root/terraform-project/checkov-outputs2.txt; then
    exit 0
else
    exit 1
fi