#!/usr/bin/bash

echo "NextCloud Calendar Desklet Installation"
echo "======================================"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    echo "Please install Python 3 first."
    exit 1
fi

# Check if pip3 is available  
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 is required but not installed."
    echo "Please install python3-pip first:"
    echo "  sudo apt install python3-pip  # On Debian/Ubuntu"
    exit 1
fi

echo "Installing Python dependencies..."
pip3 install -r requirements.txt

if [ $? -eq 0 ]; then
    echo "✓ Dependencies installed successfully"
else
    echo "✗ Failed to install dependencies"
    echo "You can try installing manually:"
    echo "  pip3 install caldav requests icalendar"
    exit 1
fi

echo ""
echo "Making ncalendar executable..."
chmod +x ncalendar

if [ -w "/usr/local/bin" ]; then
    echo "Creating symlink in /usr/local/bin..."
    sudo ln -sf "$(pwd)/ncalendar" /usr/local/bin/ncalendar
    echo "✓ ncalendar is now available system-wide"
else
    echo "Note: Could not create system-wide symlink."
    echo "You can either:"
    echo "  1. Add $(pwd) to your PATH"
    echo "  2. Or run: sudo ln -s $(pwd)/ncalendar /usr/local/bin/ncalendar"
fi

echo ""
echo "Deploying desklet..."
./deploy.sh

echo ""
echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Add the NextCloud Calendar desklet through Cinnamon's desklet manager"
echo "2. Configure your NextCloud server settings in the desklet preferences"
echo "3. Generate an app password in NextCloud Settings > Security > App passwords"
echo ""
echo "You can test the connection with:"
echo "  ncalendar --setup"
echo "  ncalendar --list-calendars"
