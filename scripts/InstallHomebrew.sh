#!/bin/bash
set -e

# sudo keep-alive, see https://gist.github.com/cowboy/3118588
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &


echo "Checking XCode CLI"
xcode-select --install 2>/dev/null || echo "Already installed"

echo "Checking Homebrew"
which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  echo "🍺 Homebrew Already installed"
fi