# Screen Detection and Automation Tool

A Windows desktop automation tool written in AutoHotkey v1.1. I originally developed this project to automate repetitive tasks in Type Soul and experiment with screen detection and Discord webhook integration.

## Features

- Real-time pixel colour detection and automatic mouse clicking
- On-screen colour picker
- Configurable scan intervals and hotkeys
- Individual monitor selection
- Scheduled repeat clicks
- Discord webhook notifications and inactivity alerts
- Graphical user interface and local settings storage

## Getting started

1. Install [AutoHotkey v1.1](https://www.autohotkey.com/).
2. Download and run `screen_automation.ahk` on Windows.
3. Choose a target colour and configure the detection settings.
4. Optionally enter a Discord webhook URL and user ID.
5. Click Start/Stop Detection to begin. The default F9 hotkey stops detection.

## Technologies

- AutoHotkey v1.1
- Windows GUI and pixel search
- HTTP POST requests and Discord webhooks
- INI configuration files

## Known limitations

- Starting detection overrides the manually selected scan area.
- The Both Monitors option does not currently cover the entire virtual desktop.
- The hotkey is disabled when detection stops; use the GUI to restart.
- Persistent matching colours can trigger repeated clicks and notifications.
- Local settings store webhook credentials in plain text. Do not publish `settings.ini`.
