#!/usr/bin/env zsh

xcode_setup() {
    if ! appExists xcode-select; then
        error_exit "xcode-select is unavailable. This setup must run on macOS."
    fi

    if xcode-select -p >/dev/null 2>&1; then
        ok "XCode Command-line Tools are already installed"
        return
    fi

    msg "Installing XCode Command-line Tools"

    local marker="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    local updates
    local product
    local list_status

    updates=$(
        touch "$marker" || exit 1
        trap 'rm -f "$marker"' EXIT
        softwareupdate --list 2>&1
    )
    list_status=$?
    if (( list_status != 0 )); then
        error_exit "Could not list Apple software updates. Check your network connection and try again."
    fi

    product=$(printf '%s\n' "$updates" |
        awk -F 'Label: ' '/^[[:space:]]*\* Label: Command Line Tools/ { print $2; exit }')
    if [[ -z "$product" ]]; then
        error_exit "No Command Line Tools update is available. You can install it with 'xcode-select --install'."
    fi

    if ! sudo softwareupdate --install "$product" --verbose; then
        error_exit "XCode Command-line Tools installation failed."
    fi

    if ! xcode-select -p >/dev/null 2>&1; then
        error_exit "Installation finished, but no active Xcode developer directory is selected."
    fi

    ok "XCode Command-line Tools installed"
}

banner

msg "Welcome! This script will install various software and customize your system settings."
msg "Before running this script, it's important to understand what it does."
echo ""
msg "Please take a moment to review the code."
echo ""
msg $'\e[1mRemember, it\'s always a good practice to read and verify code from the internet before trusting it.\e[0m'

pause

# Ask for the administrator password once upfront and keep sudo alive across all installers
sudo_keepalive

msg "Running macOS setup"
xcode_setup
source ./scripts/InstallOhMyZSH.sh
source ./scripts/InstallHomebrew.sh
source ./scripts/LinkDotfiles.sh
source ./scripts/CleanDock.sh
source ./scripts/tweaks.sh
source ./scripts/SetupPinentry.sh
