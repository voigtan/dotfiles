#!/usr/bin/env zsh

# Reference: https://macos-defaults.com/

# Close any open System Settings panes to prevent them from overriding changes
osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true

###############################################################################
# 1. Global Input & UI (-g / NSGlobalDomain)                                  #
###############################################################################

# Enable macOS Dark Mode
osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to true'

# Set Icon & Widget style to Dark ("RegularDark")
defaults write -g AppleIconAppearanceTheme -string "RegularDark"

# Set Accent Color to Pink (6) and Highlight Color to Pink
defaults write -g AppleAccentColor -int 6
defaults write -g AppleHighlightColor -string "1.000000 0.749020 0.823529 Pink"

# Use traditional ("non-natural") scroll direction
defaults write -g com.apple.swipescrolldirection -bool false

# Use F1, F2, etc. keys as standard function keys
defaults write -g com.apple.keyboard.fnState -bool true

# Show all filename extensions across macOS
defaults write -g AppleShowAllExtensions -bool true

# Enable full keyboard access for all controls (e.g. Tab in modal dialogs)
defaults write -g AppleKeyboardUIMode -int 3

# Enable subpixel font rendering on non-Apple displays
defaults write -g AppleFontSmoothing -int 1

###############################################################################
# 2. Dock & Mission Control                                                   #
###############################################################################

# Set the icon size of Dock items to 36 pixels
defaults write com.apple.dock tilesize -int 36

# Change minimize/maximize window effect to scale
defaults write com.apple.dock mineffect -string "scale"

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Enable highlight hover effect for the grid view of a stack in the Dock
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Do not show recent applications in the Dock
defaults write com.apple.dock show-recents -bool false

# Disable F11 "Show Desktop" shortcut in Mission Control
defaults write com.apple.dock showDesktop -bool false
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 36 '{ enabled = 0; value = { parameters = (65535, 65535, 0); type = "standard"; }; }'

###############################################################################
# 3. Finder                                                                   #
###############################################################################

# Always open folders in Finder's column view
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show the status bar at the bottom of Finder windows
defaults write com.apple.finder ShowStatusBar -bool true

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Unhide the ~/Library folder
chflags nohidden ~/Library

###############################################################################
# 4. Screenshots                                                              #
###############################################################################

# Save screenshots to ~/Downloads in PNG format
defaults write com.apple.screencapture location -string "$HOME/Downloads"
defaults write com.apple.screencapture type -string "png"

###############################################################################
# 5. Terminals (iTerm2)                                                       #
###############################################################################

# Do not display prompt when quitting iTerm2
defaults write com.googlecode.iterm2 PromptOnQuit -bool false

# Load custom preferences from ~/.dotfiles/iterm2
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$HOME/.dotfiles/iterm2"
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

###############################################################################
# 6. Security & Authentication (Touch ID for sudo)                            #
###############################################################################

# Enable Touch ID for sudo via /etc/pam.d/sudo_local (persists across macOS updates)
if [[ -f /etc/pam.d/sudo_local.template ]] && ! grep -q "^auth.*pam_tid\.so" /etc/pam.d/sudo_local 2>/dev/null; then
    sudo sh -c 'sed "s/^#auth/auth/" /etc/pam.d/sudo_local.template > /etc/pam.d/sudo_local'
    ok "Enabled Touch ID for sudo (/etc/pam.d/sudo_local)"
fi

###############################################################################
# Apply settings live & restart affected services                             #
###############################################################################

# Reload global (-g / NSGlobalDomain) preferences and keyboard shortcuts in the
# active macOS session immediately without requiring a logout or restart
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u >/dev/null 2>&1 || true

for app in "Dock" "Finder" "SystemUIServer"; do
  killall "$app" >/dev/null 2>&1 || true
done

ok "Applied macOS settings"
