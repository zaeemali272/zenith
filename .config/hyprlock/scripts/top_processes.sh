#!/bin/bash

# --- CONFIGURATION ---
NUM_PROCS=3
ICON_PROC="󱓞"

# --- TOP PROCESSES ---
get_top_procs() {
    # Get top processes by CPU usage, excluding the header
    procs=$(ps -eo comm,%cpu --sort=-%cpu | head -n $((NUM_PROCS + 1)) | tail -n $NUM_PROCS)
    
    output=""
    while read -r name cpu; do
        # Format: Icon Name CPU%
        output+="$ICON_PROC $name ${cpu}%\n"
    done <<< "$procs"
    
    echo -e "$output"
}

get_top_procs
