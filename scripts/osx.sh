#!/usr/bin/env zsh

function xcode_setup() {
    if ! command -v xcode-select >/dev/null 2>&1; then
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

function main() {
    msg "Running OSX setup"
    xcode_setup
    source ./scripts/InstallOhMyZSH.sh
    source ./scripts/InstallHomebrew.sh
    source ./scripts/LinkDotfiles.sh
    source ./scripts/CleanDock.sh
    source ./scripts/tweaks.sh
    source ./scripts/SetupPinentry.sh
}

main
