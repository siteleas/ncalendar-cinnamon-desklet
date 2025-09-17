#!/usr/bin/bash

# Exit on any error
set -e

# Get the script's directory
DESKLET_DIR="$HOME/.local/share/cinnamon/desklets/nextcloudCalendar@nccomputing.ca"
OUTPUT_FILE="$DESKLET_DIR/output.txt"
ERROR_LOG="$DESKLET_DIR/error.log"

# Ensure the output directory exists
mkdir -p "$DESKLET_DIR"

# Clear previous output and error log
> "$OUTPUT_FILE"
> "$ERROR_LOG"

# Log function
log_error() {
    echo "[$(date)] $1" >> "$ERROR_LOG"
}

# Check if ncalendar is available
if ! command -v ncalendar >/dev/null 2>&1; then
    error_msg="ncalendar command not found"
    log_error "$error_msg"
    echo "{\"error\": \"$error_msg\"}" > "$OUTPUT_FILE"
    exit 1
fi

# Check if config exists
if [ ! -f "$HOME/.config/ncalendar/config.ini" ]; then
    error_msg="ncalendar configuration not found"
    log_error "$error_msg"
    echo "{\"error\": \"$error_msg\"}" > "$OUTPUT_FILE"
    exit 1
fi

# Resolve binaries
NCMD=$(command -v ncalendar || echo "/usr/local/bin/ncalendar")
TIMEOUT_BIN=$(command -v timeout || echo "/usr/bin/timeout")
JQ_BIN=$(command -v jq || echo "")

# Run ncalendar command with different timeouts based on operation
TIMEOUT_DURATION=90
if [[ "$*" =~ "--list-calendars" ]]; then
    TIMEOUT_DURATION=30  # Shorter timeout for listing calendars
fi

# Run command with timeout
if ! timeout --kill-after=10 "$TIMEOUT_DURATION" "$NCMD" "$@" > "$OUTPUT_FILE" 2>> "$ERROR_LOG"; then
    error_code=$?
    if [ $error_code -eq 124 ] || [ $error_code -eq 137 ]; then
        error_msg="Command timed out after $TIMEOUT_DURATION seconds"
    else
        error_msg=$(tail -n 1 "$ERROR_LOG" 2>/dev/null || echo "Command failed with code $error_code")
    fi
    log_error "ncalendar failed: $error_msg"
    echo "{\"error\": \"$error_msg\"}" > "$OUTPUT_FILE"
    exit 1
fi

# For non-list-calendars commands, validate JSON
if [[ ! "$*" =~ "--list-calendars" ]] && [ -n "$JQ_BIN" ]; then
    if ! "$JQ_BIN" empty "$OUTPUT_FILE" 2>/dev/null; then
        error_msg="Invalid JSON output"
        log_error "$error_msg"
        echo "{\"error\": \"$error_msg\"}" > "$OUTPUT_FILE"
        exit 1
    fi
    error_code=$?
    if [ $error_code -eq 124 ]; then
        error_msg="Command timed out"
    else
        error_msg=$(tail -n 1 "$ERROR_LOG" 2>/dev/null || echo "Unknown error")
    fi
    log_error "ncalendar failed with code $error_code: $error_msg"
    echo "{\"error\": \"Calendar update failed: $error_msg\"}" > "$OUTPUT_FILE"
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
