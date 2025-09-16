# NextCloud Calendar Desklet

View your upcoming calendar events from your NextCloud server on your Cinnamon Desktop. This desklet uses `ncalendar` to pull events from NextCloud Calendar via CalDAV. You can configure every aspect of the desklet using the configure dialog.

## Requirements

- Cinnamon 3.4 or newer (tested up to 6.2)
- `ncalendar` CLI tool (included)
- Python 3.6+ with CalDAV support
- NextCloud server with Calendar app
- NextCloud app password for authentication

## Installation

1. **Install Python dependencies:**

    The desklet requires Python libraries for CalDAV access:

    ```bash
    cd /path/to/ncalendar
    pip3 install -r requirements.txt
    ```

    Or install individually:
    ```bash
    pip3 install caldav requests icalendar
    ```

2. **Make ncalendar executable and accessible:**

    ```bash
    chmod +x ncalendar
    sudo ln -s /path/to/ncalendar/ncalendar /usr/local/bin/ncalendar
    ```

    Or add the directory to your PATH in `~/.bashrc` or `~/.zshrc`:
    ```bash
    export PATH=$PATH:/path/to/ncalendar
    ```

3. **Set up NextCloud authentication:**

    - Log into your NextCloud server
    - Go to Settings > Security > App passwords  
    - Generate a new app password for "ncalendar"
    - Note down the generated password (not your regular password)

4. **Deploy and configure the desklet:**

    ```bash
    ./deploy.sh
    ```

    Then add the desklet through Cinnamon's desklet manager and configure:
    - NextCloud server URL (e.g., https://cloud.example.com)
    - Your username
    - The app password you generated

5. **Test the connection:**

    You can test ncalendar directly:
    ```bash
    ncalendar --setup
    # Follow the prompts to configure your NextCloud connection
    
    ncalendar --list-calendars
    # Should show your available calendars
    ```

## Features

- **NextCloud Integration**: Direct connection to NextCloud Calendar via CalDAV
- **Multiple Calendar Support**: Select which calendars to display
- **App Password Authentication**: Secure authentication using NextCloud app passwords  
- **Custom Date Range**: Show events for 1-30 days ahead
- **Customizable Display**:
  - Date/time formatting options
  - Color themes and transparency
  - 12/24 hour clock formats
  - Calendar-specific colors
- **Interactive Elements**:
  - Click to refresh events manually
  - Right-click menu with "Open NextCloud Calendar"
  - Auto-refresh at configurable intervals (1-1440 minutes)
- **Multiple Account Support**: Via `ncalendar --account` parameter

## Configuration

### NextCloud Server Settings

1. **Server URL**: Enter your full NextCloud server URL
2. **Username**: Your NextCloud username
3. **App Password**: Generated app password (NOT your regular password)

### Calendar Selection

1. Click "Fill in the list below with the names of all my calendars"
2. Check the calendars you want to display
3. The desklet will only show events from selected calendars

## Troubleshooting

### Common Issues

1. **"NextCloud calendar is not configured"**
   - Ensure all three fields are filled: Server URL, Username, App Password
   - Verify your NextCloud server URL is accessible

2. **"Install ncalendar to use this desklet"**
   - Make sure `ncalendar` is executable and in your PATH
   - Install required Python dependencies: `pip3 install -r requirements.txt`

3. **"Unable to retrieve events..."**
   - Test connection manually: `ncalendar --list-calendars`
   - Check that your app password is correct
   - Verify NextCloud server is accessible

4. **Empty calendar list**
   - Make sure you have calendars created in NextCloud Calendar app
   - Check that the app password has calendar access permissions

### Manual Testing

Test the ncalendar CLI directly:

```bash
# Setup account
ncalendar --setup --account myaccount

# List calendars  
ncalendar --list-calendars --account myaccount

# Get events for next 7 days
ncalendar --days 7 --account myaccount

# Get events from specific calendars
ncalendar --calendars "Personal,Work" --days 14
```

## Privacy

This desklet connects directly to your NextCloud server. No data is sent to third parties. All communication uses your server's standard CalDAV protocol with app password authentication.

## FAQ

1. **How to manually refresh the desklet?**
   Just click on the desklet. It will retrieve fresh events from your NextCloud server.

2. **Can I use multiple NextCloud accounts?**
   Yes, use the "ncalendar Account ID" setting to specify different account configurations.

3. **Does this work with NextCloud Hub 8 and newer?**
   Yes, this desklet is designed to work with NextCloud Hub 8+ and uses standard CalDAV protocols.

4. **How to report bugs?**
   Please check the console output and test the `ncalendar` command manually first. Include any error messages when reporting issues.

## License

GPL-3.0-or-later

## Credits

Based on the original Google Calendar Desklet by Gobinath.
NextCloud Calendar integration and CalDAV implementation by [Your Name].

<citations>
<document>
<document_type>WEB_PAGE</document_type>
<document_id>https://github.com/nextcloud/talk-desktop</document_id>
</document>
</citations>
