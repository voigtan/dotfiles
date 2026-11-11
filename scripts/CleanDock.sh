#!/usr/bin/env zsh

if ! appExists dockutil; then
	warn "dockutil is not installed. Please install dockutil before running this script."

	if appExists "brew" && ask "Do you want to download dockutil?" N; then
		brew install dockutil
		ok "dockutil installed"
	else
		error_exit "dockutil is required to run this script. Please install dockutil and run this script again."
	fi
fi

# Use '<space>' for a small spacer and '<large-space>' for a regular spacer.
dock_items=(
	'KeePassXC'
	Spotify
	'<space>'
	'Visual Studio Code'
	'Ghostty'
	'Google Chrome'
	'<space>'
	Slack
)

# Remove all apps from Dock
dockutil --no-restart --remove all

# Add all my apps to the Dock
for item in "${dock_items[@]}"; do
	if [[ "$item" == '<space>' ]]; then
		defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}' ||
			error_exit "Failed to add a small spacer to the Dock."
	elif [[ "$item" == '<large-space>' ]]; then
		defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}' ||
			error_exit "Failed to add a large spacer to the Dock."
	else
		dockutil --add "/Applications/${item}.app" --no-restart >/dev/null
	fi
done

killall Dock

ok "Cleaning the OSX dock"
