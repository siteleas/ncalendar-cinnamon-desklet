#!/usr/bin/bash

# NextCloud Calendar Desklet Deployment Script
# Usage: ./deploy.sh [--update-icon]

DESKLET_DIR="$HOME/.local/share/cinnamon/desklets/nextcloudCalendar@javahelps.com"
SOURCE_DIR="files/nextcloudCalendar@javahelps.com"

update_icons() {
    echo "🎨 Updating NextCloud Calendar desklet icons..."
    
    # Check if desklet is installed
    if [ ! -d "$DESKLET_DIR" ]; then
        echo "❌ Desklet not found at $DESKLET_DIR"
        echo "   Run './deploy.sh' first to install the desklet"
        exit 1
    fi
    
    # Update icon files
    echo "📁 Copying icon files..."
    cp -r "$SOURCE_DIR/icons/" "$DESKLET_DIR/"
    cp "$SOURCE_DIR/icon.png" "$DESKLET_DIR/" 2>/dev/null || true
    cp "$SOURCE_DIR/icon.svg" "$DESKLET_DIR/" 2>/dev/null || true
    
    # Clear icon caches
    echo "🔄 Clearing icon caches..."
    
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
    echo "🖥️  Attempting to refresh Cinnamon..."
    if pgrep -x cinnamon >/dev/null; then
        # Send refresh signal to Cinnamon
        dbus-send --type=method_call --dest=org.Cinnamon /org/Cinnamon org.Cinnamon.ReloadTheme 2>/dev/null || true
        
        # Alternative: try to restart just the desktop
        nohup sh -c 'sleep 1; cinnamon --replace >/dev/null 2>&1' >/dev/null 2>&1 & 
        
        echo "✅ Icon update complete!"
        echo "   If icons don't update immediately:"
        echo "   - Remove and re-add the desklet, or"
        echo "   - Press Alt+F2, type 'r', and press Enter"
    else
        echo "⚠️  Cinnamon not running - icons will update on next login"
    fi
}

full_deploy() {
    echo "🚀 Deploying NextCloud Calendar desklet..."
    
    # Remove existing installation
    if [ -d "$DESKLET_DIR" ]; then
        echo "📂 Removing existing desklet installation..."
        rm -rf "$DESKLET_DIR"
    fi
    
    # Copy all desklet files
    echo "📁 Copying desklet files..."
    cp -r "$SOURCE_DIR" ~/.local/share/cinnamon/desklets/
    
    echo "✅ Desklet deployed successfully!"
    echo "   Add it to your desktop through: Right-click → Add desklets to the desktop"
}

# Parse command line arguments
case "$1" in
    --update-icon)
        update_icons
        ;;
    --help|-h)
        echo "NextCloud Calendar Desklet Deployment Script"
        echo ""
        echo "Usage:"
        echo "  ./deploy.sh                Deploy or redeploy the complete desklet"
        echo "  ./deploy.sh --update-icon  Update only icon files and refresh caches"
        echo "  ./deploy.sh --help         Show this help message"
        echo ""
        ;;
    "")
        full_deploy
        ;;
    *)
        echo "❌ Unknown option: $1"
        echo "   Use './deploy.sh --help' for usage information"
        exit 1
        ;;
esac
