# Luxaforus

Minimalist [Luxafor](https://luxafor.com/) client application for macOS.

## How it works

There are no explicit controls for the light, instead the light turns red when the 'Do Not Disturb' mode is enabled in the macOS Notification Center and green when it's disabled. When your computer goes to sleep mode or the application is quitting, the light will be turned off.

You can speed up access to your 'Do Not Disturb' mode by setting a global keyboard shortcut for it (see 'Preferences' for details).

Luxaforus is also integrated with the Slack API to synchronise your 'Do Not Disturb' status with your Slack account.

## Credentials

While this application is open source, some credentials linked to specific accounts (e.g. Slack) are omitted from this repository and must be provided as follows:

1. Go to 'Luxaforus' project directory
2. Copy 'Credentials.plist.example' and rename it to 'Credentials.plist'
3. Replace the dummy values inside with ones you intend to use
4. Add the file to the Xcode project, by dragging it into the Project navigator

Below are some useful links on how to register your own credentials:

* Slack API: [Creating apps](https://api.slack.com/slack-apps#creating_apps)
