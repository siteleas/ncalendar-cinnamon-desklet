#!/usr/bin/bash

# NextCloud Calendar Desklet Deployment Script
# Usage: ./deploy.sh [--update-icon]

DESKLET_DIR="$HOME/.local/share/cinnamon/desklets/nextcloudCalendar@javahelps.com"
SOURCE_DIR="files/nextcloudCalendar@javahelps.com"

# Color codes for better terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

update_icons() {
    echo -e "${PURPLE}[ICON UPDATE]${NC} Updating NextCloud Calendar desklet icons..."
    
    # Check if desklet is installed
    if [ ! -d "$DESKLET_DIR" ]; then
        echo -e "${RED}[ERROR]${NC} Desklet not found at $DESKLET_DIR"
        echo "         Run './deploy.sh' first to install the desklet"
        exit 1
    fi
    
    # Update icon files
    echo -e "${CYAN}[COPY]${NC} Copying icon files..."
    cp -r "$SOURCE_DIR/icons/" "$DESKLET_DIR/"
    cp "$SOURCE_DIR/icon.png" "$DESKLET_DIR/" 2>/dev/null || true
    cp "$SOURCE_DIR/icon.svg" "$DESKLET_DIR/" 2>/dev/null || true
    
    # Clear icon caches
    echo -e "${BLUE}[CACHE]${NC} Clearing icon caches..."
    
    # Clear GTK icon cache if it exists
    if command -v gtk-update-icon-cache >/dev/null 2>&1; then
        # Update user icon cache
        [ -d "$HOME/.icons" ] && gtk-update-icon-cache "$HOME/.icons" 2>/dev/null || true
        [ -d "$HOME/.local/share/icons" ] && gtk-update-icon-cache "$HOME/.local/share/icons" 2>/dev/null || true
    fi
    
    # Clear Cinnamon's icon cache
    rm -f "$HOME/.cache/cinnamon/icon-cache.db" 2>/dev/null || true
    rm -rf "$HOME/.cache/thumbnails/" 2>/dev/null || true
    
    # Try to refresh Cinnamon (non-blocking)
    echo -e "${BLUE}[REFRESH]${NC} Attempting to refresh Cinnamon..."
    if pgrep -x cinnamon >/dev/null; then
        # Send refresh signal to Cinnamon
        dbus-send --type=method_call --dest=org.Cinnamon /org/Cinnamon org.Cinnamon.ReloadTheme 2>/dev/null || true
        
        # Alternative: try to restart just the desktop
        nohup sh -c 'sleep 1; cinnamon --replace >/dev/null 2>&1' >/dev/null 2>&1 & 
        
        echo -e "${GREEN}[SUCCESS]${NC} Icon update complete!"
        echo "          If icons don't update immediately:"
        echo "          - Remove and re-add the desklet, or"
        echo "          - Press Alt+F2, type 'r', and press Enter"
    else
        echo -e "${YELLOW}[WARNING]${NC} Cinnamon not running - icons will update on next login"
    fi
}

full_deploy() {
    echo -e "${GREEN}[DEPLOY]${NC} Deploying NextCloud Calendar desklet..."
    
    # Remove existing installation
    if [ -d "$DESKLET_DIR" ]; then
        echo -e "${YELLOW}[REMOVE]${NC} Removing existing desklet installation..."
        rm -rf "$DESKLET_DIR"
    fi
    
    # Copy all desklet files
    echo -e "${CYAN}[COPY]${NC} Copying desklet files..."
    cp -r "$SOURCE_DIR" ~/.local/share/cinnamon/desklets/
    
    # Clear Cinnamon caches to ensure new code is loaded
    echo -e "${BLUE}[CACHE]${NC} Clearing Cinnamon JavaScript cache..."
    rm -rf ~/.cache/cinnamon/ ~/.cache/gjs-* 2>/dev/null || true
    
    # Check if Cinnamon is running and reload if necessary
    if pgrep -x "cinnamon" >/dev/null; then
        echo -e "${PURPLE}[RELOAD]${NC} Reloading Cinnamon to apply changes..."
        echo -e "${YELLOW}[INFO]${NC} Your desktop will refresh momentarily..."
        
        # Give user a moment to read the message
        sleep 1
        
        # Restart Cinnamon in the background
        nohup cinnamon --replace >/dev/null 2>&1 & disown
        
        # Wait a moment for Cinnamon to start
        sleep 3
        
        echo -e "${GREEN}[RELOAD]${NC} Cinnamon reloaded successfully!"
    else
        echo -e "${YELLOW}[INFO]${NC} Cinnamon not detected - changes will apply on next login"
    fi
    
    echo -e "${GREEN}[SUCCESS]${NC} Desklet deployed with cache clearing!"
    echo "          Add it to your desktop through: Right-click → Add desklets to the desktop"
}

# Enhanced full deploy with development mode
full_deploy_dev() {
    echo -e "${PURPLE}[DEV MODE]${NC} Enhanced deployment with aggressive cache clearing..."
    
    # Kill any existing Cinnamon processes first
    echo -e "${YELLOW}[DEV]${NC} Stopping Cinnamon processes..."
    pkill -f cinnamon 2>/dev/null || true
    sleep 2
    
    # Aggressive cache clearing
    echo -e "${BLUE}[DEV]${NC} Aggressive cache clearing..."
    rm -rf ~/.cache/cinnamon/ ~/.cache/gjs-* ~/.cache/gnome-shell/ 2>/dev/null || true
    rm -rf ~/.local/share/cinnamon/extensions/cache/ 2>/dev/null || true
    
    # Run normal deployment
    full_deploy
    
    echo -e "${PURPLE}[DEV]${NC} Development deployment complete!"
}

# Parse command line arguments
case "$1" in
    --update-icon)
        update_icons
        ;;
    --dev)
        full_deploy_dev
        ;;
    --help|-h)
        echo "NextCloud Calendar Desklet Deployment Script"
        echo ""
        echo "Usage:"
        echo "  ./deploy.sh                Deploy or redeploy the complete desklet"
        echo "  ./deploy.sh --dev          Deploy with development mode (aggressive cache clearing)"
        echo "  ./deploy.sh --update-icon  Update only icon files and refresh caches"
        echo "  ./deploy.sh --help         Show this help message"
        echo ""
        ;;
    "")
        full_deploy
        ;;
    *)
        echo -e "${RED}[ERROR]${NC} Unknown option: $1"
        echo "         Use './deploy.sh --help' for usage information"
        exit 1
        ;;
esac
