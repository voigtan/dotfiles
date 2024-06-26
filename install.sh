#!/usr/bin/env bash

# Load each of the tools.
for file in ./tools/*; do
    [ -e "$file" ] || continue
    # echo "Loading tool '$file'..."
    source "$file"
done

os=$(get_os)
echo "os identified as: $os"

set -e
# Fix permissions in cases where perhaps re-running under a different user and similar scenarios
DIRS="/usr/local/var/homebrew /usr/local/Homebrew /usr/local/Caskroom /usr/local/Cellar /usr/local/bin /usr/local/etc /usr/local/lib /usr/local/sbin /usr/local/share/aclocal /usr/local/share/doc /usr/local/share/info /usr/local/share/locale /usr/local/share/man /usr/local/share/zsh"

for d in DIRS; do
    if [ -d $d ]; then
        sudo chown -R $(whoami) $d
    fi
done

if [[ "$os" == "osx" ]]; then

    chmod +x scripts/*.sh
    # Case for running as a test user on a github runner
    if id -u runner; then
        echo "Skipping Homebrew install & tweaks for Github Workflow"
        defaults write NSGlobalDomain AppleLanguages "(en-US)"
        scripts/brewfile.sh
        scripts/InstallOhMyZSH.sh
        scripts/LinkDotfiles.sh
    else
        scripts/InstallOhMyZSH.sh
        scripts/InstallHomebrew.sh
        scripts/brewfile.sh
        scripts/LinkDotfiles.sh
        scripts/CleanDock.sh
        scripts/tweaks.sh
    fi

    if ask "$os: Download the Aerial screensaver?" Y; then
        brew cask install aerial
    fi
fi

# Configure Git.
if ask "$os: Configure user for Git?" N; then
    if [[ "$os" == "osx" ]]; then
        # # Tell GPG to use pinentry-mac, and restart the agent.
        echo "pinentry-program /usr/local/bin/pinentry-mac" >> ~/.gnupg/gpg-agent.conf
        gpgconf --kill gpg-agent

        [ -e "./home/.extra" ] && source ./home/.extra
    fi
fi

# ###########################################################
# /etc/hosts -- spyware/ad blocking
# ###########################################################
if ask "$os: Install hosts file (spyware/ad blocking)?" N; then
  if curl -L -o configs/hosts https://someonewhocares.org/hosts/hosts; then
    sudo cp /etc/hosts /etc/hosts.backup
    sudo cp configs/hosts /etc/hosts
  else
  echo "Couldn't fetch the latest hosts file from https://someonewhocares.org/hosts/hosts #so skipping this step in order to not screw up your computer!"
  fi
fi
