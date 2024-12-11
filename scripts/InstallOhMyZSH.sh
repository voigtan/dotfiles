#!/usr/bin/env zsh

source ./tools/scripts.sh

FOLDER_PATH="$HOME/.oh-my-zsh"

if [ -d "$FOLDER_PATH" ]; then
    ok "Oh My Zsh is already installed in $FOLDER_PATH"
else
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed successfully"
fi

exit 0
