#!/usr/bin/env zsh

source ./tools/scripts.sh

brew update --quiet && brew bundle && brew cleanup -s

ok "Homebrew packages installed successfully"

exit 0
