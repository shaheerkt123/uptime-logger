#!/bin/bash
# Check internet connectivity
if ping -c 1 1.1.1.1 >/dev/null 2>&1 || ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    /usr/local/bin/uptime_upload
fi