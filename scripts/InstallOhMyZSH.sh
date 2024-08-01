#!/usr/bin/env bash

FOLDER_PATH="$HOME/.oh-my-zsh"

if [ -d "$FOLDER_PATH" ]; then
  echo "Oh My Zsh is already installed in $FOLDER_PATH"
  # use the ask function from the tools folder 
  if ask "Do you want to uninstall and reinstall Oh My Zsh?" N; then
    echo "installing"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/uninstall.sh)"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi
else
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
