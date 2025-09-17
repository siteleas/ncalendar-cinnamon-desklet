#!/usr/bin/bash

# Test script for NextCloud Calendar desklet monitor functionality

echo "NextCloud Calendar Desklet - Monitor Test"
echo "========================================"

echo ""
echo "Your current monitor setup:"
xrandr | grep " connected" | while IFS= read -r line; do
    echo "  $line"
done

echo ""
echo "Monitor geometry details:"
xrandr | grep " connected" | sed -n 's/\([A-Z0-9-]*\) connected[^0-9]*\([0-9]*x[0-9]*+[0-9]*+[0-9]*\).*/Monitor: \1 -> \2/p'

echo ""
echo "Primary monitor:"
xrandr | grep " connected primary" | sed -n 's/\([A-Z0-9-]*\) connected primary[^0-9]*\([0-9]*x[0-9]*+[0-9]*+[0-9]*\).*/\1 (\2)/p'

echo ""
echo "To test monitor positioning:"
echo "1. Add the NextCloud Calendar desklet to your desktop"
echo "2. Right-click on it and select 'Configure'"
echo "3. Go to the 'Display & Monitor' tab"
echo "4. Click 'Detect Available Monitors' button"
echo "5. Try changing the 'Target Monitor' dropdown"
echo "6. Check that the desklet moves to the selected monitor"

echo ""
echo "To check logs for debugging:"
echo "  journalctl --since='2 minutes ago' | grep 'NextCloud Calendar'"

echo ""
echo "Monitor coordinates for manual testing:"
xrandr | grep " connected" | while IFS= read -r line; do
    if [[ $line =~ ([A-Z0-9-]+).*([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+) ]]; then
        monitor="${BASH_REMATCH[1]}"
        width="${BASH_REMATCH[2]}"
        height="${BASH_REMATCH[3]}"
        x="${BASH_REMATCH[4]}"
        y="${BASH_REMATCH[5]}"
        echo "  $monitor: Top-left (${x},${y}) Size: ${width}x${height}"
    fi
done
