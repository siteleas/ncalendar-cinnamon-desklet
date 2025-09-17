#!/usr/bin/bash
#
# NextCloud Calendar Desklet - Enhanced Cross-Platform Installation Script
# Handles dependency installation across Debian, Ubuntu, Red Hat, Fedora, and other distributions
# Copyright (C) 2025
#

set -e  # Exit on any error

# Color codes for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
        DISTRO_NAME="$NAME"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
        DISTRO_NAME=$(cat /etc/redhat-release)
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
        DISTRO_NAME="Debian"
    else
        DISTRO="unknown"
        DISTRO_NAME="Unknown"
    fi
    
    log "Detected distribution: $DISTRO_NAME"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install system packages
install_system_packages() {
    log "Installing system dependencies..."
    
    case "$DISTRO" in
        "debian"|"ubuntu")
            # Check for apt-get
            if ! command_exists apt-get; then
                error "apt-get not found. Are you sure this is a Debian/Ubuntu system?"
                return 1
            fi
            
            log "Installing packages via apt..."
            sudo apt-get update
            
            # Install Python and pip if not available
            if ! command_exists python3; then
                sudo apt-get install -y python3
            fi
            
            if ! command_exists pip3; then
                sudo apt-get install -y python3-pip
            fi
            
            # Try to install required packages via system package manager first
            sudo apt-get install -y python3-requests python3-lxml || true
            
            # Install additional development tools if needed
            sudo apt-get install -y python3-dev python3-setuptools || true
            
            # Install emoji font support
            sudo apt-get install -y fonts-noto-color-emoji fonts-symbola || true
            ;;
            
        "fedora"|"rhel"|"centos"|"rocky"|"alma")
            # Check for package managers
            if command_exists dnf; then
                PKG_MGR="dnf"
            elif command_exists yum; then
                PKG_MGR="yum"
            else
                error "Neither dnf nor yum found. Cannot install system packages."
                return 1
            fi
            
            log "Installing packages via $PKG_MGR..."
            
            # Install Python and pip if not available
            if ! command_exists python3; then
                sudo $PKG_MGR install -y python3
            fi
            
            if ! command_exists pip3; then
                sudo $PKG_MGR install -y python3-pip
            fi
            
            # Try to install required packages via system package manager first
            sudo $PKG_MGR install -y python3-requests python3-lxml || true
            
            # Install additional development tools if needed
            sudo $PKG_MGR install -y python3-devel python3-setuptools || true
            
            # Install emoji font support
            sudo $PKG_MGR install -y google-noto-emoji-fonts || true
            ;;
            
        "arch"|"manjaro")
            # Check for pacman
            if ! command_exists pacman; then
                error "pacman not found. Are you sure this is an Arch-based system?"
                return 1
            fi
            
            log "Installing packages via pacman..."
            
            # Install Python and pip if not available
            if ! command_exists python3; then
                sudo pacman -S --noconfirm python
            fi
            
            if ! command_exists pip3; then
                sudo pacman -S --noconfirm python-pip
            fi
            
            # Try to install required packages via system package manager first
            sudo pacman -S --noconfirm python-requests python-lxml || true
            
            # Install emoji font support
            sudo pacman -S --noconfirm noto-fonts-emoji || true
            ;;
            
        "opensuse"|"sles")
            # Check for zypper
            if ! command_exists zypper; then
                error "zypper not found. Are you sure this is an openSUSE system?"
                return 1
            fi
            
            log "Installing packages via zypper..."
            
            # Install Python and pip if not available
            if ! command_exists python3; then
                sudo zypper install -y python3
            fi
            
            if ! command_exists pip3; then
                sudo zypper install -y python3-pip
            fi
            
            # Try to install required packages via system package manager first
            sudo zypper install -y python3-requests python3-lxml || true
            
            # Install emoji font support
            sudo zypper install -y noto-coloremoji-fonts || true
            ;;
            
        *)
            warning "Unknown distribution: $DISTRO_NAME"
            warning "Attempting to use pip3 for dependency installation..."
            ;;
    esac
}

# Enhanced Python dependency installation
install_python_dependencies() {
    log "Installing Python dependencies..."
    
    # Check Python version compatibility
    python3 -c "
import sys
if sys.version_info < (3, 6):
    print('ERROR: Python 3.6+ is required')
    sys.exit(1)
else:
    print(f'✓ Python {sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro} is compatible')
"
    
    if [ $? -ne 0 ]; then
        error "Python version check failed"
        return 1
    fi
    
    # Create minimal requirements that work with older library versions
    cat > requirements_minimal.txt << EOF
# Minimal requirements that work with older CalDAV versions
caldav>=0.11.0
requests>=2.20.0
icalendar>=4.0.3
lxml>=4.0.0
EOF
    
    # Try different installation methods
    local install_success=false
    
    # Method 1: Try pip3 install with user flag first
    if ! $install_success; then
        log "Attempting pip3 install --user..."
        if pip3 install --user -r requirements_minimal.txt 2>/dev/null; then
            install_success=true
            success "Dependencies installed via pip3 --user"
        fi
    fi
    
    # Method 2: Try system-wide pip3 install
    if ! $install_success; then
        log "Attempting system-wide pip3 install..."
        if sudo pip3 install -r requirements_minimal.txt 2>/dev/null; then
            install_success=true
            success "Dependencies installed system-wide via pip3"
        fi
    fi
    
    # Method 3: Try pip3 with --break-system-packages (for newer systems)
    if ! $install_success; then
        log "Attempting pip3 install with --break-system-packages..."
        if pip3 install --break-system-packages -r requirements_minimal.txt 2>/dev/null; then
            install_success=true
            success "Dependencies installed via pip3 --break-system-packages"
        fi
    fi
    
    # Method 4: Try creating a virtual environment
    if ! $install_success; then
        log "Attempting virtual environment installation..."
        if python3 -m venv ncalendar_venv 2>/dev/null; then
            source ncalendar_venv/bin/activate
            pip install -r requirements_minimal.txt
            deactivate
            
            # Update ncalendar script to use virtual environment
            sed -i '1s|#!/usr/bin/env python3|#!/usr/bin/env '"$(pwd)"'/ncalendar_venv/bin/python3|' ncalendar
            
            install_success=true
            success "Dependencies installed in virtual environment"
            warning "ncalendar script updated to use virtual environment"
        fi
    fi
    
    # Method 5: Manual installation of individual packages
    if ! $install_success; then
        log "Attempting manual installation of core packages..."
        for package in "requests" "lxml"; do
            pip3 install --user "$package" 2>/dev/null || sudo pip3 install "$package" 2>/dev/null || true
        done
        
        # Test if basic functionality works
        if python3 -c "import requests, xml.etree.ElementTree; print('✓ Core dependencies available')" 2>/dev/null; then
            install_success=true
            warning "Partial dependency installation successful"
        fi
    fi
    
    if ! $install_success; then
        error "Failed to install Python dependencies through all methods"
        warning "The enhanced ncalendar should still work with basic functionality"
        warning "Some features may be limited due to missing dependencies"
    fi
    
    # Clean up temporary requirements file
    rm -f requirements_minimal.txt
    
    return 0
}

# Test ncalendar functionality
test_ncalendar() {
    log "Testing ncalendar functionality..."
    
    # Make executable
    chmod +x ncalendar
    
    # Test basic functionality
    if ./ncalendar --help >/dev/null 2>&1; then
        success "ncalendar basic functionality test passed"
    else
        error "ncalendar basic functionality test failed"
        return 1
    fi
    
    # Test dependency imports
    python3 -c "
try:
    import requests, xml.etree.ElementTree as ET, json, configparser
    print('✓ Core dependencies imported successfully')
except ImportError as e:
    print(f'⚠ Warning: Some dependencies missing: {e}')
    print('  Basic functionality should still work')
" || warning "Some Python dependencies may be missing"
    
    return 0
}

# Setup system-wide access
setup_system_access() {
    log "Setting up system-wide access..."
    
    local install_path="/usr/local/bin/ncalendar"
    local current_path="$(pwd)/ncalendar"
    
    # Try to create symlink in /usr/local/bin
    if [ -w "/usr/local/bin" ] || sudo -n true 2>/dev/null; then
        if sudo ln -sf "$current_path" "$install_path" 2>/dev/null; then
            success "ncalendar installed to $install_path"
        else
            warning "Could not create system-wide symlink"
            log "You can manually run: sudo ln -sf '$current_path' '$install_path'"
        fi
    else
        warning "No write access to /usr/local/bin"
        log "Add to your PATH: export PATH=\"$(pwd):\$PATH\""
        log "Or create symlink manually: sudo ln -sf '$current_path' '$install_path'"
    fi
}

# Deploy desklet files
deploy_desklet() {
    log "Deploying desklet files..."
    
    if [ -f "./deploy.sh" ]; then
        if ./deploy.sh; then
            success "Desklet deployed successfully"
        else
            error "Desklet deployment failed"
            return 1
        fi
    else
        error "deploy.sh not found"
        return 1
    fi
}

# Create installation report
create_report() {
    local report_file="installation_report.txt"
    
    log "Creating installation report..."
    
    cat > "$report_file" << EOF
NextCloud Calendar Desklet v0.2.115 Installer
==============================================
Date: $(date)
System: $DISTRO_NAME
Distribution: $DISTRO

Installation Summary:
- Python version: $(python3 --version 2>/dev/null || echo "Not available")
- pip3 available: $(command_exists pip3 && echo "Yes" || echo "No")
- ncalendar executable: $([ -x "./ncalendar" ] && echo "Yes" || echo "No")
- System-wide access: $([ -L "/usr/local/bin/ncalendar" ] && echo "Yes" || echo "No")

Dependency Status:
$(python3 -c "
try:
    import requests
    print('- requests: Available')
except ImportError:
    print('- requests: Missing')

try:
    import xml.etree.ElementTree
    print('- xml.etree.ElementTree: Available')
except ImportError:
    print('- xml.etree.ElementTree: Missing')

try:
    import json
    print('- json: Available')
except ImportError:
    print('- json: Missing')

try:
    import configparser
    print('- configparser: Available')
except ImportError:
    print('- configparser: Missing')

try:
    import caldav
    print('- caldav: Available')
except ImportError:
    print('- caldav: Missing')

# Check for emoji font support
font_paths = [
    '/usr/share/fonts/noto-emoji',       # RedHat/Fedora
    '/usr/share/fonts/noto',             # Arch
    '/usr/share/fonts/truetype/noto',    # Debian/Ubuntu
    '/usr/share/fonts/noto-coloremoji'   # OpenSUSE
]

for path in font_paths:
    if os.path.exists(path):
        print('- Emoji font support: Available')
        break
else:
    print('- Emoji font support: Missing')
" 2>/dev/null)

Next Steps:
1. Add the NextCloud Calendar desklet through Cinnamon's desklet manager
2. Configure your NextCloud server settings in the desklet preferences  
3. Generate an app password in NextCloud Settings > Security > App passwords

Test Commands:
- Test basic functionality: ./ncalendar --help
- Setup account: ./ncalendar --setup
- List calendars: ./ncalendar --list-calendars

For support, provide this report along with any error messages.
EOF

    success "Installation report created: $report_file"
}

# Main installation function
main() {
    echo -e "${PURPLE}===============================================${NC}"
    echo -e "${PURPLE} NextCloud Calendar Desklet Enhanced Installer${NC}"  
    echo -e "${PURPLE}===============================================${NC}"
    echo
    
    # Detect distribution
    detect_distro
    
    # Check basic requirements
    if ! command_exists python3; then
        error "Python 3 is not installed"
        log "Please install Python 3 first, then re-run this script"
        exit 1
    fi
    
    # Install system packages
    if install_system_packages; then
        success "System packages installed"
    else
        warning "Some system packages may not have been installed"
    fi
    
    # Install Python dependencies  
    if install_python_dependencies; then
        success "Python dependencies handled"
    else
        warning "Some Python dependencies may be missing"
    fi
    
    # Test ncalendar
    if test_ncalendar; then
        success "ncalendar functionality verified"
    else
        error "ncalendar functionality test failed"
        exit 1
    fi
    
    # Setup system access
    setup_system_access
    
    # Deploy desklet
    if deploy_desklet; then
        success "Desklet deployment complete"
    else
        error "Desklet deployment failed"
        exit 1
    fi
    
    # Create report
    create_report
    
    echo
    success "Installation completed successfully!"
    echo
    
    # Check emoji font support
    local emoji_fonts_installed=false
    for path in '/usr/share/fonts/noto-emoji' '/usr/share/fonts/noto' '/usr/share/fonts/truetype/noto' '/usr/share/fonts/noto-coloremoji'; do
        if [ -d "$path" ]; then
            emoji_fonts_installed=true
            break
        fi
    done
    
    if [ "$emoji_fonts_installed" = false ]; then
        warning "Emoji fonts not found - some icons may not display correctly"
        log "To enable emoji support, install one of these packages:"
        log "- Debian/Ubuntu: fonts-noto-color-emoji fonts-symbola"
        log "- RedHat/Fedora: google-noto-emoji-fonts"
        log "- Arch: noto-fonts-emoji"
        log "- OpenSUSE: noto-coloremoji-fonts"
        echo
    fi
    
    log "You can now:"
    log "1. Add the NextCloud Calendar desklet through Cinnamon's desklet manager"
    log "2. Configure your NextCloud server in the desklet settings"
    log "3. Test the connection with: ncalendar --setup"
    echo
    log "Installation report saved: installation_report.txt"
}

# Run main function
main "$@"
