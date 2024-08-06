#!/usr/bin/env zsh

source ./tools/scripts.sh

banner

msg "Welcome! This script will install various software and customize your system settings."
msg "Before running this script, it's important to understand what it does."
echo ""
msg "Please take a moment to review the code."
echo ""
msg "Remember, it's always a good practice to read and verify code from the internet before trusting it."

pause

# sudo keep-alive, see https://gist.github.com/cowboy/3118588
# sudo -v
# while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

os=$(get_os)

case "$os" in
    "osx")
        ./scripts/osx.sh
        ;;
    # "linux")
    #     ./scripts/linux.sh
    #     ;;
    *)
        echo "Unsupported operating system: $os"
        ;;
esac

# If .extra exists, source it
[ -e "./home/.extra" ] && source ./home/.extra
