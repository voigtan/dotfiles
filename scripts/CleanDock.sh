#!/bin/sh

apps=(
	'Google Chrome Canary'
	'Visual Studio Code - Insiders'
	Spotify
	Slack
)

# Remove all apps from Dock
dockutil --no-restart --remove all

# Add all my apps to the Dock
for app in "${apps[@]}"
do
	dockutil --add "/Applications/${app}.app" --no-restart
done

killall Dock