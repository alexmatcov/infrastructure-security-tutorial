#!/bin/bash

if command -v checkov >/dev/null 2>&1 && checkov -v >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi