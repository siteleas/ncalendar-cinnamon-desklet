#!/usr/bin/bash

# Exit on any error
set -e

# Get the script's directory
DESKLET_DIR="$HOME/.local/share/cinnamon/desklets/nextcloudCalendar@javahelps.com"
OUTPUT_FILE="$DESKLET_DIR/output.txt"

# Ensure the output directory exists
mkdir -p "$DESKLET_DIR"

# Clear previous output
> "$OUTPUT_FILE"

# Run ncalendar and capture both stdout and stderr
if ! ncalendar "$@" > "$OUTPUT_FILE" 2>&1; then
    echo "{\"error\": \"Failed to retrieve calendar events\"}" > "$OUTPUT_FILE"
    exit 1
fi

# For list-calendars command, don't validate as array
if [[ ! "$*" =~ "--list-calendars" ]]; then
    # Validate JSON output for events (should be an array)
    if ! grep -q "^\[" "$OUTPUT_FILE"; then
        echo "{\"error\": \"Invalid calendar data received\"}" > "$OUTPUT_FILE"
        exit 1
    fi
fi

exit 0
