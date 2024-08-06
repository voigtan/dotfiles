#!/usr/bin/env zsh

source ./tools/scripts.sh

if ! appExists brew; then
    # Install Homebrew
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    eval "$(/opt/homebrew/bin/brew shellenv)"

    ok "Homebrew installed"
else
    ok "Homebrew Already installed"
fi

brew update --quiet && brew bundle && brew cleanup -s

ok "Homebrew packages installed successfully"
