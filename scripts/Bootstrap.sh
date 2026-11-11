#!/usr/bin/env zsh

banner

msg "Welcome! This script will install various software and customize your system settings."
msg "Before running this script, it's important to understand what it does."
echo ""
msg "Please take a moment to review the code."
echo ""
msg $'\e[1mRemember, it\'s always a good practice to read and verify code from the internet before trusting it.\e[0m'

pause

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` timestamp until the script has finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT

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

os=$(get_os)

case "$os" in
    "osx")
        source ./scripts/osx.sh
        ;;
    # "linux")
    #     source ./scripts/linux.sh
    #     ;;
    *)
        echo "Unsupported operating system: $os"
        ;;
esac
