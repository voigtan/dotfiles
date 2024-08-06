#!/usr/bin/env zsh

source ./tools/scripts.sh

# Define the apps to be added to the Dock
apps=(
	'KeePassXC'
	'Visual Studio Code - Insiders'
	'Google Chrome'
	Spotify
	Slack
)

# Remove all apps from Dock
dockutil --no-restart --remove all

# Add all my apps to the Dock
for app in "${apps[@]}"; do
	dockutil --add "/Applications/${app}.app" --no-restart
done

killall Dock

ok "Cleaning the OSX dock"
