#!/usr/bin/bash

# NextCloud Calendar Desklet Diagnostic Script
# Helps troubleshoot desklet loading and configuration issues

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

DESKLET_DIR="$HOME/.local/share/cinnamon/desklets/nextcloudCalendar@javahelps.com"

echo -e "${BLUE}[DIAGNOSTIC]${NC} NextCloud Calendar Desklet Troubleshooting"
echo "==========================================================="

# Check if desklet is installed
echo -e "${CYAN}[CHECK]${NC} Verifying desklet installation..."
if [ -d "$DESKLET_DIR" ]; then
    echo -e "${GREEN}[SUCCESS]${NC} Desklet directory found at: $DESKLET_DIR"
else
    echo -e "${RED}[ERROR]${NC} Desklet not installed. Run './deploy.sh' first"
    exit 1
fi

# Check required files
echo -e "${CYAN}[CHECK]${NC} Verifying required files..."
required_files=(
    "desklet.js"
    "metadata.json"
    "settings-schema.json"
    "lib/utility.js"
    "lib/xdate.js"
    "writeEvents.sh"
)

for file in "${required_files[@]}"; do
    if [ -f "$DESKLET_DIR/$file" ]; then
        echo -e "${GREEN}[OK]${NC}     $file"
    else
        echo -e "${RED}[MISSING]${NC} $file"
    fi
done

# Validate JSON files
echo -e "${CYAN}[CHECK]${NC} Validating JSON syntax..."
if command -v jq >/dev/null 2>&1; then
    for json_file in "metadata.json" "settings-schema.json"; do
        if jq . "$DESKLET_DIR/$json_file" >/dev/null 2>&1; then
            echo -e "${GREEN}[VALID]${NC}  $json_file"
        else
            echo -e "${RED}[INVALID]${NC} $json_file - JSON syntax error"
        fi
    done
else
    echo -e "${YELLOW}[WARNING]${NC} jq not available - cannot validate JSON syntax"
fi

# Check JavaScript syntax (basic)
echo -e "${CYAN}[CHECK]${NC} Checking JavaScript syntax..."
if command -v node >/dev/null 2>&1; then
    if node -c "$DESKLET_DIR/desklet.js" 2>/dev/null; then
        echo -e "${GREEN}[VALID]${NC}  desklet.js syntax"
    else
        echo -e "${RED}[ERROR]${NC}  desklet.js syntax error"
        node -c "$DESKLET_DIR/desklet.js"
    fi
    
    if node -c "$DESKLET_DIR/lib/utility.js" 2>/dev/null; then
        echo -e "${GREEN}[VALID]${NC}  utility.js syntax"
    else
        echo -e "${RED}[ERROR]${NC}  utility.js syntax error"
        node -c "$DESKLET_DIR/lib/utility.js"
    fi
else
    echo -e "${YELLOW}[WARNING]${NC} Node.js not available - cannot validate JavaScript syntax"
fi

# Check ncalendar CLI
echo -e "${CYAN}[CHECK]${NC} Verifying ncalendar CLI..."
if command -v ncalendar >/dev/null 2>&1; then
    echo -e "${GREEN}[FOUND]${NC}   ncalendar command available"
    ncalendar --help | head -3
else
    echo -e "${RED}[MISSING]${NC} ncalendar command not found in PATH"
    if [ -f "./ncalendar" ]; then
        echo -e "${YELLOW}[INFO]${NC}    ncalendar found in current directory - run 'sudo ln -s $(pwd)/ncalendar /usr/local/bin/'"
    fi
fi

# Check Python dependencies
echo -e "${CYAN}[CHECK]${NC} Verifying Python dependencies..."
python_deps=("caldav" "requests" "icalendar")
for dep in "${python_deps[@]}"; do
    if python3 -c "import $dep" 2>/dev/null; then
        echo -e "${GREEN}[OK]${NC}     python3-$dep"
    else
        echo -e "${RED}[MISSING]${NC} python3-$dep"
    fi
done

# Check Cinnamon compatibility
echo -e "${CYAN}[CHECK]${NC} Checking Cinnamon compatibility..."
if command -v cinnamon >/dev/null 2>&1; then
    cinnamon_version=$(cinnamon --version | grep -oP '\d+\.\d+' | head -1)
    echo -e "${GREEN}[INFO]${NC}    Cinnamon version: $cinnamon_version"
    
    # Check if version is supported (3.4 to 6.2)
    supported_versions=("3.4" "3.6" "3.8" "4.0" "4.2" "4.4" "4.6" "5.0" "5.2" "5.4" "5.6" "5.8" "6.0" "6.2")
    if printf '%s\n' "${supported_versions[@]}" | grep -q "^$cinnamon_version$"; then
        echo -e "${GREEN}[SUPPORTED]${NC} Version $cinnamon_version is supported"
    else
        echo -e "${YELLOW}[WARNING]${NC} Version $cinnamon_version may not be officially supported"
    fi
else
    echo -e "${RED}[ERROR]${NC} Cinnamon not found"
fi

# Recent logs check
echo -e "${CYAN}[CHECK]${NC} Checking for recent errors..."
if journalctl --since="10 minutes ago" 2>/dev/null | grep -qi "nextcloud\|desklet.*error\|javascript.*error"; then
    echo -e "${YELLOW}[WARNING]${NC} Found recent error logs - check with: journalctl --since='10 minutes ago' | grep -i error"
else
    echo -e "${GREEN}[OK]${NC}     No obvious recent errors found"
fi

# File permissions
echo -e "${CYAN}[CHECK]${NC} Checking file permissions..."
if [ -x "$DESKLET_DIR/writeEvents.sh" ]; then
    echo -e "${GREEN}[OK]${NC}     writeEvents.sh is executable"
else
    echo -e "${RED}[ERROR]${NC}  writeEvents.sh is not executable - run: chmod +x $DESKLET_DIR/writeEvents.sh"
fi

echo ""
echo -e "${BLUE}[SUMMARY]${NC} Diagnostic complete!"
echo ""
echo "Next steps:"
echo "1. If all checks passed, try removing and re-adding the desklet"
echo "2. Check Cinnamon logs: journalctl --since='5 minutes ago' | grep -i cinnamon"
echo "3. Restart Cinnamon: Alt+F2, type 'r', press Enter"
echo "4. If issues persist, check ~/.xsession-errors for JavaScript errors"
