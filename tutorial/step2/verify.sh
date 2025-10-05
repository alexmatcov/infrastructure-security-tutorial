#!/bin/bash

if command -v checkov >/dev/null 2>&1 && checkov -v >/dev/null 2>&1; then
    echo "Checkov is installed"
    exit 0
else
    echo "Checkov is not installed or not in PATH"
    echo "Please wait for the installation to complete"
    exit 1
fi