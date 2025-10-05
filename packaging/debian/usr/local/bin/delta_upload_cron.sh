#!/bin/bash
# Check internet connectivity
if ping -c 1 1.1.1.1 >/dev/null 2>&1 || ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    python3 /usr/local/bin/delta_upload.py
fi