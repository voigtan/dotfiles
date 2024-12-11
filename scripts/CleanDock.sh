#!/usr/bin/env zsh

source ./tools/scripts.sh

if ! appExists dockutil; then
	warn "dockutil is not installed. Please install dockutil before running this script."

	if appExists "brew" && ask "Do you want to download dockutil?" N; then
		brew install dockutil
		ok "dockutil installed"
	else
		error_exit "dockutil is required to run this script. Please install dockutil and run this script again."
	fi
fi

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

exit 0
