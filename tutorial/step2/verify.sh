#!/bin/bash
if checkov --version >/dev/null 2>&1; then
    exit 0
else
    exit 1
fi