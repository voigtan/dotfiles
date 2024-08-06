#!/usr/bin/env bash
set -e

chmod +x scripts/*.sh

source ./tools/scripts.sh

# check if zsh is installed
if ! appExists zsh; then
    echo "zsh is not installed, please install zsh first"
    exit 1
fi

# Fix permissions in cases where perhaps re-running under a different user and similar scenarios
DIRS="/usr/local/var/homebrew /usr/local/Homebrew /usr/local/Caskroom /usr/local/Cellar /usr/local/bin /usr/local/etc /usr/local/lib /usr/local/sbin /usr/local/share/aclocal /usr/local/share/doc /usr/local/share/info /usr/local/share/locale /usr/local/share/man /usr/local/share/zsh"

for d in DIRS; do
    if [ -d $d ]; then
        sudo chown -R $(whoami) $d
    fi
done

./scripts/Bootstrap.sh

# ###########################################################
# /etc/hosts -- spyware/ad blocking
# ###########################################################
# if ask "$os: Install hosts file (spyware/ad blocking)?" N; then
#   if curl -L -o configs/hosts https://someonewhocares.org/hosts/hosts; then
#     sudo cp /etc/hosts /etc/hosts.backup
#     sudo cp configs/hosts /etc/hosts
#   else
#   echo "Couldn't fetch the latest hosts file from https://someonewhocares.org/hosts/hosts #so skipping this step in order to not screw up your computer!"
#   fi
# fi
