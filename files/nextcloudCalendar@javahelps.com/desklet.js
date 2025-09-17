/*
* NextCloud Calendar Desklet displays your agenda based on your NextCloud Calendar in Cinnamon desktop.
*
* Copyright (C) 2025
*
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program.  If not, see <http:*www.gnu.org/licenses/>.
*/

"use strict";

const Cinnamon = imports.gi.Cinnamon;
const Clutter = imports.gi.Clutter;
const Desklet = imports.ui.desklet;
const GLib = imports.gi.GLib;
const Lang = imports.lang;
const Mainloop = imports.mainloop;
const Settings = imports.ui.settings;
const Util = imports.misc.util;
const Gettext = imports.gettext;
const Gio = imports.gi.Gio;
const Gtk = imports.gi.Gtk;
const St = imports.gi.St;
const PopupMenu = imports.ui.popupMenu;
const ModalDialog = imports.ui.modalDialog;

// Import local libraries
imports.searchPath.unshift(GLib.get_home_dir() + "/.local/share/cinnamon/desklets/nextcloudCalendar@javahelps.com/lib");
const XDate = imports.utility.XDate;
const SpawnReader = imports.utility.SpawnReader;
const Event = imports.utility.Event;
const CalendarUtility = new imports.utility.CalendarUtility();


const UUID = "nextcloudCalendar@javahelps.com";
const SEPARATOR_LINE = "\n\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015\u2015";

Gettext.bindtextdomain(UUID, GLib.get_home_dir() + "/.local/share/locale");

const TEXT_WIDTH = 250;
const FONT_SIZE = 14;
const HOME_PATH = GLib.get_home_dir();

function _(str) {
    return Gettext.dgettext(UUID, str);
}

function NextCloudCalendarDesklet(metadata, deskletID) {
    this._init(metadata, deskletID);
}

NextCloudCalendarDesklet.prototype = {
    __proto__: Desklet.Desklet.prototype,

    /**
     * Initialize the desklet.
     */
    _init(metadata, deskletID) {
        Desklet.Desklet.prototype._init.call(this, metadata, deskletID);
        this.metadata = metadata;
        this.maxSize = 7000;
        this.maxWidth = 0;
        this.updateID = null;
        this.updateInProgress = false;
        this.eventsList = [];
        this.lastDate = null;
        this.today = new XDate().toString("yyyy-MM-dd");
        this.tomorrow = new XDate().addDays(1).toString("yyyy-MM-dd");

        this._updateDecoration();

        // Bind properties
        this.settings = new Settings.DeskletSettings(this, this.metadata["uuid"], deskletID);
        this.settings.bind("serverUrl", "serverUrl", this.onCalendarParamsChanged, null);
        this.settings.bind("username", "username", this.onCalendarParamsChanged, null);
        this.settings.bind("appPassword", "appPassword", this.onCalendarParamsChanged, null);
        this.settings.bind("ncalendarAccount", "ncalendarAccount", this.onCalendarParamsChanged, null);
        this.settings.bind("calendarNames", "calendarNames", this.onCalendarParamsChanged, null);
        this.settings.bind("interval", "interval", this.onCalendarParamsChanged, null);
        this.settings.bind("delay", "delay", this.onCalendarParamsChanged, null);
        this.settings.bind("use_24h_clock", "use_24h_clock", this.onDeskletFormatChanged, null);
        this.settings.bind("date_format", "date_format", this.onDeskletFormatChanged, null);
        this.settings.bind("today_format", "today_format", this.onDeskletFormatChanged, null);
        this.settings.bind("tomorrow_format", "tomorrow_format", this.onDeskletFormatChanged, null);
        this.settings.bind("zoom", "zoom", this.onDeskletFormatChanged, null);
        this.settings.bind("textcolor", "textcolor", this.onDeskletFormatChanged, null);
        this.settings.bind("alldaytextcolor", "alldaytextcolor", this.onDeskletFormatChanged, null);
        this.settings.bind("bgcolor", "bgcolor", this.onDeskletFormatChanged, null);
        this.settings.bind("diff_calendar", "diff_calendar", this.onDeskletFormatChanged, null);
        this.settings.bind("show_location", "show_location", this.onDeskletFormatChanged, null);
        this.settings.bind("location_color", "location_color", this.onDeskletFormatChanged, null);
        this.settings.bind("transparency", "transparency", this.onDeskletFormatChanged, null);
        this.settings.bind("cornerradius", "cornerradius", this.onDeskletFormatChanged, null);
        
        // Monitor and position settings - use same pattern as style settings for live updates
        this.settings.bind("target_monitor", "target_monitor", this.onDisplaySettingsChanged, null);
        this.settings.bind("position_x", "position_x", this.onDisplaySettingsChanged, null);
        this.settings.bind("position_y", "position_y", this.onDisplaySettingsChanged, null);
        this.settings.bind("auto_position", "auto_position", this.onDisplaySettingsChanged, null);
        
        // Initialize monitor detection
        this.availableMonitors = [];
        
        this.setCalendarName();
        
        // Delay monitor detection and positioning to ensure desklet is fully initialized
        Mainloop.timeout_add(1000, Lang.bind(this, function() {
            this.detectMonitors();
            this.applyInitialPosition();
            return false; // Don't repeat
        }));

        // Set header
        this.setHeader(_("NextCloud Calendar"));
        // Set "Open NextCloud Calendar" menu item
        Gtk.IconTheme.get_default().append_search_path(metadata.path + "/icons/");
        let openNextCloudCalendarItem = new PopupMenu.PopupIconMenuItem(_("Open NextCloud Calendar"), "nextcloud-calendar", St.IconType.SYMBOLIC);
        openNextCloudCalendarItem.connect("activate", (event) => {
            if (this.serverUrl && this.serverUrl !== "") {
                GLib.spawn_command_line_async("xdg-open " + this.serverUrl + "/apps/calendar");
            }
        });
        this._menu.addMenuItem(openNextCloudCalendarItem);
        
        // Add separator and refresh item
        this._menu.addMenuItem(new PopupMenu.PopupSeparatorMenuItem());
        let refreshEventsItem = new PopupMenu.PopupIconMenuItem(_("Refresh Events"), "view-refresh", St.IconType.SYMBOLIC);
        refreshEventsItem.connect("activate", Lang.bind(this, function() {
            this.retrieveEventsIfAuthorized();
        }));
        this._menu.addMenuItem(refreshEventsItem);
        
        // Set up ncalendar configuration when credentials are available
        this.setupNCaendarIfNeeded();
        
        // Start the update loop
        this.updateLoop();
    },

    //////////////////////////////////////////// Event Listeners ////////////////////////////////////////////
    /**
     * Called when user updates settings related to formatting.
     */
    onDeskletFormatChanged() {
        if (this.eventsList.length > 0) {
            this.resetWidget();
            for (let event of this.eventsList) {
                event.useTwentyFourHour = this.use_24h_clock;
                this.addEventToWidget(event);
            }
        } else {
            this.retrieveEventsIfAuthorized();
        }
    },

    /**
     * Called when user changes the settings which require new events.
     */
    onCalendarParamsChanged() {
        this.setCalendarName();
        this.setupNCaendarIfNeeded();
        if (this.updateID > 0) {
            Mainloop.source_remove(this.updateID);
        }
        this.updateID = null;
        this.retrieveEventsIfAuthorized();
    },

    /**
     * Called when the user clicks the button to populate the calendarName field with the names of all their calendars.
     */
    onAllNamesButtonClicked() {
        let reader = new SpawnReader();
        let command = ["ncalendar", "--output", "txt", "--list-calendars"];
        this.addAccountID(command, this.ncalendarAccount);
        // List of calendars already selected by user:
        let registeredCalendarNames = this.calendarName.toString().split(",");
        // List of all the user's calendars:
        var calendars = []; // We will populate it !
        this.calendarNames = [];
        reader.spawn(HOME_PATH, command, (output) => {
            let names = output.toString().trim().split(/\r?\n/);
            names.forEach((name) => {
                let display = (registeredCalendarNames.indexOf(name) > -1);
                calendars.push({
                    name,
                    display
                });
            });
            this.calendarNames = calendars; // Refreshes the array in Settings.
        });
    },

    /**
     * Called when the desklet is removed.
     */
    on_desklet_removed() {
        if (this.updateID > 0) {
            Mainloop.source_remove(this.updateID);
        }
        this.updateID = null;
    },

    /**
     * Called when user clicks on the desklet.
     * Changed behavior: Don't refresh events on desklet click to avoid clearing content.
     */
    on_desklet_clicked(event) {
        // Only refresh if there are no events visible, or if it's been more than update interval
        if (this.eventsList.length === 0) {
            this.retrieveEventsIfAuthorized();
        }
        // For manual refresh, users can use the right-click menu
    },

    /**
     * Show a simple event details dialog.
     */
    showEventDetailsDialog(eventData) {
        try {
            global.log("[NextCloud Calendar] Showing event details for: " + eventData.name);
            
            // Build event details text
            let details = "Event: " + eventData.name;
            details += "\nDate: " + eventData.startDateText;
            if (eventData.location) {
                details += "\nLocation: " + eventData.location;
            }
            if (eventData.calendar_name) {
                details += "\nCalendar: " + eventData.calendar_name;
            }
            
            // Show desktop notification with event details
            let cmd = 'notify-send "NextCloud Calendar Event" "' + details.replace(/"/g, '\\"').replace(/\n/g, '\\n') + '"';
            GLib.spawn_command_line_async(cmd);
            
            // Also try to open in browser if server URL is configured
            if (this.serverUrl && this.serverUrl !== "") {
                let baseUrl = this.serverUrl.replace(/\/$/, '');
                let calendarUrl = baseUrl + "/apps/calendar";
                
                // Try to open to the specific date if available
                if (eventData.startDateText) {
                    let dateStr = eventData.startDateText.replace(/-/g, '/');
                    calendarUrl = baseUrl + "/apps/calendar/dayGridMonth/" + dateStr;
                }
                
                global.log("[NextCloud Calendar] Opening URL: " + calendarUrl);
                GLib.spawn_command_line_async("xdg-open " + calendarUrl);
            }
            
        } catch (e) {
            global.logError("[NextCloud Calendar] Error showing event details: " + e.toString());
            GLib.spawn_command_line_async('notify-send "NextCloud Calendar" "Error showing event details"');
        }
    },

    /**
     * Show event details in a modal dialog.
     */
    showEventDetailsModal(event) {
        try {
            let dialog = new ModalDialog.ModalDialog();
            
            // Set dialog properties
            dialog.contentLayout.style_class = 'calendar-event-dialog';
            dialog.contentLayout.style = 'padding: 20px; min-width: 400px; background-color: rgba(0,0,0,0.9); border-radius: 10px;';
            
            // Title
            let titleLabel = new St.Label({
                text: event.name || 'Event Details',
                style_class: 'calendar-event-title',
                style: 'font-size: 18pt; font-weight: bold; color: white; margin-bottom: 15px;'
            });
            dialog.contentLayout.add(titleLabel);
            
            // Event details container
            let detailsBox = new St.BoxLayout({
                vertical: true,
                style: 'spacing: 8px;'
            });
            
            // Add event details
            this.addEventDetail(detailsBox, '📅 Date:', this.formatEventDateRange(event));
            
            if (event.startTime !== '00:00' || event.endTime !== '00:00') {
                let timeText = this.formatEventTimeRange(event);
                if (timeText) {
                    this.addEventDetail(detailsBox, '🕐 Time:', timeText);
                }
            } else {
                this.addEventDetail(detailsBox, '📅 Type:', 'All Day Event');
            }
            
            if (event.location && event.location !== '') {
                this.addEventDetail(detailsBox, '📍 Location:', event.location);
            }
            
            // Add calendar info if available
            if (event.calendar_name) {
                let calendarText = event.calendar_name;
                if (event.color) {
                    calendarText = '● ' + calendarText;
                }
                this.addEventDetail(detailsBox, '📚 Calendar:', calendarText, event.color);
            }
            
            dialog.contentLayout.add(detailsBox);
            
            // Action buttons
            let buttonBox = new St.BoxLayout({
                style: 'spacing: 10px; margin-top: 20px;'
            });
            
            // Open in NextCloud button
            if (this.serverUrl && this.serverUrl !== '') {
                let openButton = new St.Button({
                    label: 'Open in NextCloud',
                    style_class: 'calendar-button',
                    style: 'padding: 8px 16px; background-color: #0082c9; color: white; border-radius: 5px;'
                });
                openButton.connect('clicked', Lang.bind(this, function() {
                    let baseUrl = this.serverUrl.replace(/\/$/, '');
                    let calendarUrl = baseUrl + "/apps/calendar";
                    if (event.startDate) {
                        let eventDate = event.startDate.toString('yyyy/MM/dd');
                        calendarUrl = baseUrl + "/apps/calendar/dayGridMonth/" + eventDate;
                    }
                    GLib.spawn_command_line_async("xdg-open " + calendarUrl);
                    dialog.close();
                }));
                buttonBox.add(openButton);
            }
            
            // Close button
            let closeButton = new St.Button({
                label: 'Close',
                style_class: 'calendar-button',
                style: 'padding: 8px 16px; background-color: #666666; color: white; border-radius: 5px; margin-left: 10px;'
            });
            closeButton.connect('clicked', Lang.bind(this, function() {
                dialog.close();
            }));
            buttonBox.add(closeButton);
            
            dialog.contentLayout.add(buttonBox);
            
            // Show the dialog
            dialog.open();
            
        } catch (e) {
            global.logError("[NextCloud Calendar] Error creating event details modal: " + e.toString());
        }
    },

    /**
     * Add a detail row to the event details box.
     */
    addEventDetail(container, label, value, color = null) {
        let rowBox = new St.BoxLayout({
            style: 'spacing: 10px; margin-bottom: 5px;'
        });
        
        let labelWidget = new St.Label({
            text: label,
            style: 'color: #cccccc; font-weight: bold; min-width: 80px;'
        });
        
        let valueStyle = 'color: white;';
        if (color) {
            valueStyle += ' color: ' + color + ';';
        }
        
        let valueWidget = new St.Label({
            text: value,
            style: valueStyle
        });
        
        rowBox.add(labelWidget);
        rowBox.add(valueWidget);
        container.add(rowBox);
    },

    /**
     * Format event date range for display.
     */
    formatEventDateRange(event) {
        try {
            let startDate = event.startDate || new XDate(event.start_date);
            let endDate = event.endDate || new XDate(event.end_date);
            
            let startDateStr = startDate.toString('MMMM dd, yyyy');
            
            // Check if it spans multiple days
            if (startDate.diffDays(endDate) < -1) {
                let endDateStr = endDate.toString('MMMM dd, yyyy');
                return startDateStr + ' - ' + endDateStr;
            } else {
                return startDateStr;
            }
        } catch (e) {
            return event.start_date || 'Unknown date';
        }
    },

    /**
     * Format event time range for display.
     */
    formatEventTimeRange(event) {
        try {
            if (event.startTime === '00:00' && event.endTime === '00:00') {
                return null; // All day event
            }
            
            let startTime = this.formatTime(event.startTime);
            let endTime = this.formatTime(event.endTime);
            
            if (startTime === endTime) {
                return startTime;
            } else {
                return startTime + ' - ' + endTime;
            }
        } catch (e) {
            return event.startTime + ' - ' + event.endTime;
        }
    },

    /**
     * Format time based on user preference (12h/24h).
     */
    formatTime(timeStr) {
        try {
            if (this.use_24h_clock) {
                return timeStr;
            }
            
            let time = timeStr.toString().match(/^([01]\d|2[0-3]):([0-5]\d)$/);
            if (time) {
                let hours = parseInt(time[1]);
                let minutes = time[2];
                let ampm = hours < 12 ? 'AM' : 'PM';
                if (hours === 0) hours = 12;
                if (hours > 12) hours -= 12;
                return hours + ':' + minutes + ' ' + ampm;
            }
            return timeStr;
        } catch (e) {
            return timeStr;
        }
    },

    /**
     * Called when display/monitor settings change - follows same pattern as style settings.
     */
    onDisplaySettingsChanged() {
        global.log("[NextCloud Calendar] Display settings changed - target_monitor: " + this.target_monitor + 
                   ", auto_position: " + this.auto_position + 
                   ", position_x: " + this.position_x + 
                   ", position_y: " + this.position_y);
        
        // Apply positioning immediately using the same pattern as format changes
        this.applyPositionAndRefresh();
    },

    /**
     * Called when the user clicks to detect monitors.
     */
    onDetectMonitorsClicked() {
        this.detectMonitors();
    },

    //////////////////////////////////////////// Utility Functions ////////////////////////////////////////////
    /**
     * Set up ncalendar configuration if credentials are available.
     */
    setupNCaendarIfNeeded() {
        if (this.serverUrl && this.username && this.appPassword && 
            this.serverUrl !== "" && this.username !== "" && this.appPassword !== "") {
            
            // Set up ncalendar account configuration
            let accountId = this.ncalendarAccount || "default";
            let configCommand = `echo "${this.serverUrl}|${this.username}|${this.appPassword}" | python3 -c "
import sys
import configparser
from pathlib import Path

config_dir = Path.home() / '.config' / 'ncalendar'
config_file = config_dir / 'config.ini'
config_dir.mkdir(parents=True, exist_ok=True)

config = configparser.ConfigParser()
if config_file.exists():
    config.read(config_file)

line = sys.stdin.readline().strip()
server_url, username, app_password = line.split('|', 2)

account_id = '${accountId}'
if account_id not in config:
    config.add_section(account_id)

config[account_id]['server_url'] = server_url
config[account_id]['username'] = username
config[account_id]['app_password'] = app_password

with open(config_file, 'w') as f:
    config.write(f)
"`;
            
            Util.spawnCommandLineAsync(configCommand);
        }
    },

    /**
     * Set the this.calendarName value.
     */
    setCalendarName() {
        try {
            var names = [];
            for (var i = 0; i < this.calendarNames.length; i++) {
                if (this.calendarNames[i]["display"] === true) {
                    names.push(this.calendarNames[i]["name"]);
                }
            }
            this.calendarName = names.join(",");
        } catch (e) {
            this.calendarName = "";
        }
    },

    /**
     * Construct ncalendar command to retrieve events.
     */
    getCalendarCommand(accountId) {
        let command = ["ncalendar", "--output", "json"];
        command.push("--days");
        if (this.interval == null) {
            this.interval = 7; // Default interval is 7 days
        }
        command.push(this.interval.toString());
        this.addCalendarList(command);
        this.addAccountID(command, accountId);
        return command;
    },

    /**
     * Convert string line to Event object and store in a list.
     * This method also add the event to widget.
     */
    addEvent(eventLine) {
        let events = [];
        try {
            events = JSON.parse(eventLine);
        } catch (e) {
            throw e;
        }
        if (events.length === 0) {
            this.window.add(CalendarUtility.label(_("No events found"), this.zoom, this.textcolor));
        } else {
            events.forEach((element) => {
                let event = new Event(element, this.use_24h_clock);
                this.eventsList.push(event);
                this.addEventToWidget(event);
            });
        }
    },

    /**
     * Append given event to widget.
     */
    addEventToWidget(event) {
        // Create date header
        if (this.lastDate === null || event.startDate.diffDays(this.lastDate) <= -1) {
            let leadingNewline = "";
            if (this.lastDate) {
                leadingNewline = "\n\n";
            }
            this.lastDate = event.startDate;
            let label = CalendarUtility.label(leadingNewline + this.formatEventDate(event.startDateText) + SEPARATOR_LINE, this.zoom, this.textcolor);
            this.window.add(label);
            if (label.width > this.maxWidth) {
                this.maxWidth = label.width;
            }
        }

        // Create event row
        let box = CalendarUtility.container();
        this.window.add(box);

        let textWidth = this.maxWidth;
        let lblBullet;
        // Add a bullet to differentiate calendar
        if (this.diff_calendar) {
            lblBullet = CalendarUtility.label("\u2022 ", this.zoom, event.color);
            box.add(lblBullet);
            textWidth = textWidth - lblBullet.width;
        }

        let dateText = event.formatEventDuration(this.lastDate);
        if (dateText) {
            let lblEvent = CalendarUtility.label(event.name, this.zoom, this.textcolor);
            let lblDate = CalendarUtility.label(dateText, this.zoom, this.textcolor);
            box.add(lblEvent, {
                expand: true,
                x_fill: true,
                align: St.Align.START
            });
            box.add(lblDate);
            lblEvent.width = textWidth - lblDate.width - 50 * this.zoom * global.ui_scale;
            
            // Make event clickable
            this.makeEventClickable(box, event);
        } else {
            let lblEvent = CalendarUtility.label(event.name, this.zoom, this.alldaytextcolor);
            lblEvent.width = textWidth;
            box.add(lblEvent);
            
            // Make event clickable
            this.makeEventClickable(box, event);
        }

        if (this.show_location && event.location !== "") {
            let locationBox = CalendarUtility.container();
            if (this.diff_calendar) {
                let lblEmpty = CalendarUtility.label("", this.zoom, this.textcolor);
                lblEmpty.width = lblBullet.width;
                locationBox.add(lblEmpty);
            }
            let lblLocation = CalendarUtility.label(event.location, this.zoom, this.location_color, true, 8);
            lblLocation.style = lblLocation.style + "; font-style: italic;";
            lblLocation.width = textWidth;
            locationBox.add(lblLocation);
            this.window.add(locationBox);
        }
    },

    /**
     * Make event clickable by adding a button to the event row.
     */
    makeEventClickable(eventBox, eventData) {
        try {
            // Add a small clickable button/icon next to the event
            let clickButton = new St.Button({
                label: '🔗',  // Link icon
                style_class: 'event-click-button',
                style: 'padding: 2px; margin-left: 5px; font-size: 10pt;'
            });
            
            clickButton.connect('clicked', Lang.bind(this, function() {
                global.log("[NextCloud Calendar] Event button clicked: " + eventData.name);
                this.showEventDetailsDialog(eventData);
            }));
            
            // Add the button to the event box
            eventBox.add(clickButton);
            
            global.log("[NextCloud Calendar] Added click button for: " + eventData.name);
            
        } catch (e) {
            global.logError("[NextCloud Calendar] Error making event clickable: " + e.toString());
        }
    },

    /**
     * Show loading indicator.
     */
    showLoadingIndicator() {
        this.resetWidget(true);
        let loadingLabel = CalendarUtility.label("🔄 Loading events...", this.zoom, this.textcolor);
        this.window.add(loadingLabel);
    },
    
    /**
     * Reset internal states and widget CalendarUtility.
     */
    resetWidget(resetEventsList = false) {
        if (resetEventsList) {
            this.eventsList = [];
            this.today = new XDate().toString("yyyy-MM-dd");
            this.tomorrow = new XDate().addDays(1).toString("yyyy-MM-dd");
        }
        this.lastDate = null;
        this.window = CalendarUtility.window(this.cornerradius, this.textcolor, this.bgcolor, this.transparency);
        this.setContent(this.window);
        this.maxWidth = 0;
    },

    /**
     * Updates every user set seconds
     **/
    updateLoop() {
        this.retrieveEventsIfAuthorized();
        this.updateID = Mainloop.timeout_add_seconds(this.delay * 60, Lang.bind(this, this.updateLoop));
    },

    /**
     * Returns well formatted string (for this.today_format, this.tomorrow_format and this.date_format).
     * This fixes a bug that occurs, for example, when 'today' is replaced by 'aujourd'hui' by a French-speaking user.
     */
    formatDatePattern(t) {
        var ret = t;
        if (t.indexOf("'") > -1) {
            let index1 = t.indexOf("'"); // first apostrophe
            let index2 = t.lastIndexOf("'"); // last apostrophe
            let sub = t.substr(index1 + 1, index2 - index1 - 1); // all between the first and last apostrophe
            if (sub.indexOf("'") > -1) { // there is at least one other apostrophe
                let sub2 = sub.replace("'", "'"); // replaces all other apostrophe &apos; by the &rsquo; character
                ret = t.replace(sub, sub2);
            }
        }
        return ret;
    },

    /**
     * Format date using given pattern.
     */
    formatEventDate(dateText) {
        if (this.today === dateText) {
            return new XDate(dateText).toString(this.formatDatePattern(this.today_format)).toUpperCase();
        } else if (this.tomorrow === dateText) {
            return new XDate(dateText).toString(this.formatDatePattern(this.tomorrow_format)).toUpperCase();
        } else {
            return new XDate(dateText).toString(this.formatDatePattern(this.date_format)).toUpperCase();
        }
    },

    retrieveEventsIfAuthorized() {
        let accountId = this.ncalendarAccount || "default";
        
        // Show loading indicator first
        this.showLoadingIndicator();
        
        // Check if we have credentials configured
        if (!this.serverUrl || !this.username || !this.appPassword ||
            this.serverUrl === "" || this.username === "" || this.appPassword === "") {
            this.showNCaendarStatus("Not Configured", accountId);
            return;
        }
        
        try {
            // Try to retrieve events directly
            this.retrieveEvents(accountId);
        } catch (e) {
            this.showErrorMessage(e.toString());
        }
    },

    showNCaendarStatus(status, accountId) {
        let message = _("NextCloud calendar is not configured");
        if (status === "Not Configured") {
            message = _("Please configure NextCloud server settings");
        }
        // Show the status on widget
        this.resetWidget(true);
        let label = CalendarUtility.label(message, this.zoom, this.textcolor);
        let hint = _("Configure: ") + "Server URL, Username, and App Password";
        let lblHint = CalendarUtility.label(hint, this.zoom, this.location_color, true, 8);
        lblHint.style = lblHint.style + "; font-style: italic;";

        this.window.add(label);
        this.window.add(lblHint);
    },

    showErrorMessage(errorMessage) {
        this.resetWidget(true);
        let message = _("Unknown Error");
        let hint = errorMessage;
        if (errorMessage.includes("No such file or directory") || errorMessage.includes("ncalendar")) {
            message = _("Install ncalendar to use this desklet.");
            hint = _("Run: ") + "pip3 install -r requirements.txt";
        }
        let label = CalendarUtility.label(message, this.zoom, this.textcolor);
        let lblHint = CalendarUtility.label(hint, this.zoom, this.location_color, true, 8);
        lblHint.style = lblHint.style + "; font-style: italic;";
        this.window.add(label);
        this.window.add(lblHint);
    },

    /**
     * Method to update the text/reading of the file
     **/
    retrieveEvents(accountId) {
        if (this.updateInProgress) {
            return;
        }
        this.updateInProgress = true;
        var outputReceived = false;
        try {
            // Execute the command to retrieve the calendar events.
            let reader = new SpawnReader();
            let error = false;
            reader.spawn(HOME_PATH, this.getCalendarCommand(accountId), (output) => {
                this.resetWidget(true);
                if (!outputReceived) {
                    outputReceived = true;
                }
                let eventLine = output.toString();
                try {
                    this.addEvent(eventLine);
                    error = false;
                } catch (e) {
                    // Some JSON parse errors happened. May be because of first time authentication
                    // Wait until reaching last line of the output because the last line may be a valid events JSON
                    error = true;
                }
            });
            if (error) {
                let label = CalendarUtility.label(_("Unable to retrieve events..."), this.zoom, this.textcolor);
                this.window.add(label);
            }
        } catch (e) {
            global.logError(e);
        } finally {
            this.updateInProgress = false;
        }
    },

    /**
     * Add selected calendars to the command.
     * @param {String[]} command ncalendar command
     */
    addCalendarList(command) {
        if (this.calendarName != "") {
            command.push("--calendars");
            command.push(this.calendarName);
        }
    },

    /**
     * Append the account id to the command if valid.
     * @param {String[]} command ncalendar command
     * @param {String} accountId ncalendar account id
     */
    addAccountID(command, accountId) {
        if (accountId != null && accountId !== "") {
            command.push("--account", accountId);
        }
    },

    //////////////////////////////////////////// Position Management Functions ////////////////////////////////////////////
    /**
     * Apply position changes immediately like style changes - called when display settings change.
     */
    applyPositionAndRefresh() {
        global.log("[NextCloud Calendar] applyPositionAndRefresh called");
        
        // Ensure monitors are detected
        if (!this.availableMonitors || this.availableMonitors.length === 0) {
            this.detectMonitors();
        }
        
        // Use a small delay to allow the settings to fully update
        Mainloop.timeout_add(100, Lang.bind(this, function() {
            try {
                this.performImmediatePositioning();
            } catch (e) {
                global.logError("[NextCloud Calendar] Error in applyPositionAndRefresh: " + e.toString());
            }
            return false; // Don't repeat
        }));
    },
    
    /**
     * Apply initial position settings on desklet startup.
     */
    applyInitialPosition() {
        global.log("[NextCloud Calendar] applyInitialPosition called");
        global.log("[NextCloud Calendar] Settings - target_monitor: " + this.target_monitor + 
                   ", auto_position: " + this.auto_position + 
                   ", position_x: " + this.position_x + 
                   ", position_y: " + this.position_y);
        
        // Give the desklet a moment to fully render before positioning
        Mainloop.timeout_add(500, Lang.bind(this, function() {
            try {
                this.performImmediatePositioning();
            } catch (e) {
                global.logError("[NextCloud Calendar] Error in applyInitialPosition: " + e.toString());
            }
            return false; // Don't repeat
        }));
    },
    
    /**
     * Perform immediate positioning - the core positioning logic.
     */
    performImmediatePositioning() {
        if (this.auto_position) {
            this.applyMonitorSettings();
        } else {
            this.applyManualPosition();
        }
    },
    
    //////////////////////////////////////////// Monitor Management Functions ////////////////////////////////////////////
    /**
     * Detect available monitors and their configurations.
     */
    detectMonitors() {
        try {
            let display = global.display;
            if (display && display.get_n_monitors) {
                let nMonitors = display.get_n_monitors();
                global.log("[NextCloud Calendar] Detected " + nMonitors + " monitors");
                
                this.availableMonitors = [];
                for (let i = 0; i < nMonitors; i++) {
                    let geometry = display.get_monitor_geometry(i);
                    let isPrimary = (i === display.get_primary_monitor());
                    
                    this.availableMonitors.push({
                        index: i,
                        x: geometry.x,
                        y: geometry.y,
                        width: geometry.width,
                        height: geometry.height,
                        primary: isPrimary
                    });
                    
                    global.log("[NextCloud Calendar] Monitor " + i + ": " + 
                              geometry.width + "x" + geometry.height + 
                              " at (" + geometry.x + "," + geometry.y + ")" +
                              (isPrimary ? " [PRIMARY]" : ""));
                }
                
                // Log current desklet position for reference
                if (this.actor) {
                    let currentX = this.actor.get_x();
                    let currentY = this.actor.get_y();
                    let currentMonitor = this.getMonitorAtPosition(currentX, currentY);
                    global.log("[NextCloud Calendar] Current desklet position: (" + currentX + "," + currentY + ")" +
                              (currentMonitor ? " on monitor " + currentMonitor.index : " (no monitor match)"));
                }
            } else {
                global.logError("[NextCloud Calendar] Display or monitor detection not available");
            }
        } catch (e) {
            global.logError("[NextCloud Calendar] Error detecting monitors: " + e.toString());
        }
    },

    /**
     * Apply monitor settings based on target_monitor selection.
     */
    applyMonitorSettings() {
        global.log("[NextCloud Calendar] applyMonitorSettings called with target_monitor: " + this.target_monitor);
        
        if (!this.availableMonitors || this.availableMonitors.length === 0) {
            global.log("[NextCloud Calendar] No monitors cached, detecting...");
            this.detectMonitors();
        }
        
        if (!this.availableMonitors || this.availableMonitors.length === 0) {
            global.logError("[NextCloud Calendar] No monitors available for positioning");
            return;
        }
        
        let targetMonitor = null;
        
        try {
            switch (this.target_monitor) {
                case "primary":
                    targetMonitor = this.availableMonitors.find(m => m.primary);
                    global.log("[NextCloud Calendar] Looking for primary monitor: " + (targetMonitor ? "found index " + targetMonitor.index : "not found"));
                    break;
                case "monitor0":
                    targetMonitor = this.availableMonitors[0];
                    global.log("[NextCloud Calendar] Selecting monitor 0: " + (targetMonitor ? "found" : "not available"));
                    break;
                case "monitor1":
                    targetMonitor = this.availableMonitors[1];
                    global.log("[NextCloud Calendar] Selecting monitor 1: " + (targetMonitor ? "found" : "not available"));
                    break;
                case "monitor2":
                    targetMonitor = this.availableMonitors[2];
                    global.log("[NextCloud Calendar] Selecting monitor 2: " + (targetMonitor ? "found" : "not available"));
                    break;
                case "auto":
                default:
                    // Use current monitor or primary as fallback
                    if (this.actor) {
                        let currentX = this.actor.get_x();
                        let currentY = this.actor.get_y();
                        targetMonitor = this.getMonitorAtPosition(currentX, currentY) || 
                                      this.availableMonitors.find(m => m.primary) ||
                                      this.availableMonitors[0];
                        global.log("[NextCloud Calendar] Auto-select mode: using " + 
                                  (targetMonitor ? "monitor " + targetMonitor.index : "no monitor found"));
                    } else {
                        targetMonitor = this.availableMonitors.find(m => m.primary) || this.availableMonitors[0];
                        global.log("[NextCloud Calendar] Auto-select mode (no actor): using " + 
                                  (targetMonitor ? "monitor " + targetMonitor.index : "no monitor found"));
                    }
                    break;
            }
            
            if (targetMonitor) {
                global.log("[NextCloud Calendar] Target monitor found: " + targetMonitor.index + 
                          " (" + targetMonitor.width + "x" + targetMonitor.height + 
                          " at " + targetMonitor.x + "," + targetMonitor.y + ")");
                
                if (this.auto_position) {
                    // Position desklet at a reasonable default location on the target monitor
                    let newX = targetMonitor.x + 50;  // 50px from left edge
                    let newY = targetMonitor.y + 50;  // 50px from top edge
                    
                    global.log("[NextCloud Calendar] Auto-positioning to (" + newX + "," + newY + ") on monitor " + targetMonitor.index);
                    let success = this.moveToPosition(newX, newY);
                    if (!success) {
                        global.log("[NextCloud Calendar] Position change may require desklet restart for full effect");
                    }
                } else {
                    global.log("[NextCloud Calendar] Auto-position disabled, not moving desklet");
                }
            } else {
                global.logError("[NextCloud Calendar] No target monitor found for setting: " + this.target_monitor);
            }
        } catch (e) {
            global.logError("[NextCloud Calendar] Error applying monitor settings: " + e.toString());
        }
    },

    /**
     * Apply manual positioning.
     */
    applyManualPosition() {
        try {
            if (this.position_x !== undefined && this.position_y !== undefined) {
                global.log("[NextCloud Calendar] Applying manual position (" + 
                          this.position_x + "," + this.position_y + ")");
                let success = this.moveToPosition(this.position_x, this.position_y);
                if (!success) {
                    global.log("[NextCloud Calendar] Manual position change may require desklet restart for full effect");
                }
            } else {
                global.log("[NextCloud Calendar] Manual position coordinates not defined");
            }
        } catch (e) {
            global.logError("[NextCloud Calendar] Error applying manual position: " + e.toString());
        }
    },

    /**
     * Get the monitor that contains the given position.
     */
    getMonitorAtPosition(x, y) {
        if (!this.availableMonitors) return null;
        
        for (let monitor of this.availableMonitors) {
            if (x >= monitor.x && x < monitor.x + monitor.width &&
                y >= monitor.y && y < monitor.y + monitor.height) {
                return monitor;
            }
        }
        return null;
    },

    /**
     * Move desklet to specified position using enhanced immediate positioning.
     */
    moveToPosition(x, y) {
        try {
            global.log("[NextCloud Calendar] moveToPosition called with (" + x + "," + y + ")");
            
            if (!this.actor) {
                global.logError("[NextCloud Calendar] No actor available for positioning");
                return false;
            }
            
            // Log current position for comparison
            let currentX = this.actor.get_x();
            let currentY = this.actor.get_y();
            global.log("[NextCloud Calendar] Current position: (" + currentX + "," + currentY + ") -> Moving to: (" + x + "," + y + ")");
            
            // Try positioning methods in order of preference
            let success = false;
            
            // Method 1: set_position (most reliable)
            if (this.actor.set_position) {
                this.actor.set_position(x, y);
                global.log("[NextCloud Calendar] Used actor.set_position");
                success = true;
            }
            // Method 2: Direct property assignment
            else if (this.actor.hasOwnProperty('x') && this.actor.hasOwnProperty('y')) {
                this.actor.x = x;
                this.actor.y = y;
                global.log("[NextCloud Calendar] Set actor.x and actor.y directly");
                success = true;
            }
            // Method 3: move method
            else if (this.actor.move) {
                this.actor.move(x, y);
                global.log("[NextCloud Calendar] Used actor.move");
                success = true;
            }
            
            // Verify the position was set (with small delay for async operations)
            Mainloop.timeout_add(50, Lang.bind(this, function() {
                let newX = this.actor.get_x();
                let newY = this.actor.get_y();
                if (Math.abs(newX - x) > 10 || Math.abs(newY - y) > 10) {
                    global.log("[NextCloud Calendar] Position verification: requested (" + x + "," + y + "), actual (" + newX + "," + newY + ") - position may have been overridden");
                } else {
                    global.log("[NextCloud Calendar] Position successfully applied: (" + newX + "," + newY + ")");
                }
                return false;
            }));
            
            return success;
            
        } catch (e) {
            global.logError("[NextCloud Calendar] Error in moveToPosition: " + e.toString());
            return false;
        }
    }
};

function main(metadata, deskletID) {
    let desklet = new NextCloudCalendarDesklet(metadata, deskletID);
    return desklet;
}
