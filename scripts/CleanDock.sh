#!/bin/bash

dockutil --remove 'Launchpad'
dockutil --remove 'Safari'
dockutil --remove 'Mail'
dockutil --remove 'FaceTime'
dockutil --remove 'Messages'
dockutil --remove 'Maps'
dockutil --remove 'Contacts'
dockutil --remove 'Calendar'
dockutil --remove 'Reminders'
dockutil --remove 'Notes'
dockutil --remove 'Music'
dockutil --remove 'Podcasts'
dockutil --remove 'TV'
dockutil --remove 'App Store'
dockutil --remove 'System Preferences'

dockutil --no-restart --add "/Applications/Google Chrome Canary.app"
dockutil --no-restart --add "/Applications/Spotify.app"

killall Dock