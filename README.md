![New Creation Computing Logo](/home/jim/Pictures/logos/ncc-logo.png)

# NextCloud Calendar Desklet v0.2.115

**Alpha Release - Enhanced Cinnamon Desktop Calendar with Professional Features**

## Version Control

This project uses semantic versioning (0.x.yyy) for alpha/development releases. Version management is restricted to repository owners and administrators.

Current version 0.2.115 indicates:
- Pre-release alpha status (0)
- Second feature set (2)
- Build 115

See [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Detailed version numbering scheme
- How to contribute code
- Development guidelines

---

## 🏢 **Developed by New Creation Computing**

**Website:** http://nccomputing.ca  
**Lead Developer:** Jim Blake  
**Email:** support@nccomputing.ca  
**GitHub:** https://github.com/siteleas/ncalendar-cinnamon-desklet

---

## ✨ **Enhanced Features**

- **🔄 Live Positioning** - Multi-monitor support with real-time positioning
- **🖱️ Interactive Events** - Click events to open in NextCloud web interface
- **📱 Cross-Platform** - Advanced installation scripts for all Linux distributions
- **⚡ Robust Error Handling** - Professional-grade dependency management
- **🎨 Customizable Interface** - Clean, modern design with extensive theming options
- **🔒 Secure Authentication** - NextCloud app password integration
- **📅 Multiple Calendars** - Support for unlimited calendar sources
- **⚙️ Smart Configuration** - Automatic setup and configuration detection

## 🚀 **Quick Installation**

### **Standard Installation:**
```bash
git clone https://github.com/siteleas/ncalendar-cinnamon-desklet.git
cd ncalendar-cinnamon-desklet
chmod +x install.sh
./install.sh
```

### **Development Installation:**
```bash
./install.sh --dev  # Aggressive cache clearing for development
```

### **Icon Updates Only:**
```bash
./install.sh --update-icon  # Update icons without full restart
```

## ⚙️ **Configuration**

1. **Add Desklet:** Right-click desktop → "Add desklets to the desktop" → Select "NextCloud Calendar Desklet"
2. **Configure:** Right-click desklet → "Configure"
3. **Server Setup:** Enter NextCloud URL, username, and app password
4. **Customize:** Set positioning, colors, and refresh intervals

## 📋 **System Requirements**

- **Linux Distribution:** Debian, Ubuntu, Red Hat, Fedora, Arch, openSUSE
- **Cinnamon:** Version 3.4 - 6.2+
- **Python:** 3.6 or higher
- **Dependencies:** Auto-installed (caldav, icalendar, lxml, requests)

## 🛠️ **Professional Development**

This desklet represents professional-grade software development with:
- Advanced error handling and logging
- Cross-platform compatibility testing
- Comprehensive installation automation
- Multi-monitor positioning algorithms
- Secure credential management

## 📄 **License**

This software is **FREE and OPEN SOURCE** under custom license terms requiring attribution.

**Key Points:**
- ✅ Free for personal and commercial use
- ✅ Modification and distribution permitted
- ⚠️ **Credits to New Creation Computing must remain in all distributions**
- ⚠️ Attribution required in source code and user interfaces

See [LICENSE](LICENSE) file for complete terms.

## 👏 **Credits & Acknowledgments**

**Primary Development:** New Creation Computing (Jim Blake)
**Original Inspiration:** Google Calendar Desklet by Gobinath  
**Authentication Patterns:** NextCloud Talk Desktop client  

---

**© 2025 New Creation Computing - All Rights Reserved**

*This project maintains the free and open source nature while ensuring proper attribution to the development team.*
