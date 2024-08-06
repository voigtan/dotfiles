#!/usr/bin/env zsh

source ./tools/scripts.sh

function xcode_setup() {
    if [ ! -x "$(command -v xcode-select)" ]; then
        warn "Please install XCode Command-line Tools in order to install homebrew and its packages."
    fi

    if ! appExists xcode-select; then
        xcode-select --install
        ok "XCode Command-line Tools installed"
    else
        ok "XCode Command-line Tools already installed"
    fi
}

function brew_setup() {
    if ! appExists brew; then
        # Install Homebrew
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Setup Homebrew envvars.
        if [[ $(arch) == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [[ $(arch) == "i386" ]]; then
            eval "$(/usr/local/bin/brew shellenv)"
        else
            error_exit "Invalid CPU arch: $(arch)" >&2
        fi

        ok "Homebrew installed"
    else
        ok "Homebrew Already installed"
    fi
}

function main() {
    msg "Running OSX setup"
    xcode_setup
    scripts/InstallOhMyZSH.sh
    brew_setup
    scripts/InstallHomebrew.sh
    scripts/LinkDotfiles.sh
    scripts/CleanDock.sh
    scripts/tweaks.sh
    scripts/SetupPinentry.sh
}

main
