#!/usr/bin/env zsh

source ./tools/scripts.sh

msg "Running OSX setup"

if [ ! -x "$(command -v xcode-select)" ]; then
    warn "Please install XCode Command-line Tools in order to install homebrew and its packages."
fi

if ! appExists xcode-select; then
    xcode-select --install
    ok "XCode Command-line Tools installed"
else
    ok "XCode Command-line Tools already installed"
fi

scripts/InstallOhMyZSH.sh
scripts/InstallHomebrew.sh
scripts/LinkDotfiles.sh
scripts/CleanDock.sh
scripts/tweaks.sh
scripts/SetupPinentry.sh
