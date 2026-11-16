#!/usr/bin/env zsh

# @description Check whether a command is available in PATH.
# @arg $1 string Name of the command to check.
# @exitcode 0 If the command exists.
# @exitcode 1 If the command does not exist.
appExists() {
    command -v "$1" &>/dev/null
}

# @description Ensure a required CLI tool is installed, prompting to install via Homebrew if missing.
# @arg $1 string Name of the command / Homebrew formula.
# @exitcode 0 If the command is already installed or was installed via Homebrew.
# @exitcode 1 Exits the script if the command is missing and not installed.
require_brew_app() {
    local app="$1"
    if appExists "$app"; then
        return 0
    fi

    warn "$app is not installed. Please install $app before running this script."
    if appExists "brew" && ask "Do you want to download $app?" N; then
        brew install "$app"
        ok "$app installed"
    else
        error_exit "$app is required to run this script. Please install $app and run this script again."
    fi
}
