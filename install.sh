#!/usr/bin/env zsh
set -e

chmod +x scripts/*.sh tools/*.sh 2>/dev/null || true

source ./tools/scripts.sh

# Fix permissions in cases where perhaps re-running under a different user and similar scenarios
DIRS=(
    /usr/local/var/homebrew
    /usr/local/Homebrew
    /usr/local/Caskroom
    /usr/local/Cellar
    /usr/local/bin
    /usr/local/etc
    /usr/local/lib
    /usr/local/sbin
    /usr/local/share/aclocal
    /usr/local/share/doc
    /usr/local/share/info
    /usr/local/share/locale
    /usr/local/share/man
    /usr/local/share/zsh
)

for d in "${DIRS[@]}"; do
    if [[ -d "$d" ]]; then
        sudo chown -R "$(whoami)" "$d"
    fi
done

source ./scripts/Bootstrap.sh
