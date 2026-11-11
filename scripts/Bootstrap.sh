#!/usr/bin/env zsh

banner

msg "Welcome! This script will install various software and customize your system settings."
msg "Before running this script, it's important to understand what it does."
echo ""
msg "Please take a moment to review the code."
echo ""
msg "Remember, it's always a good practice to read and verify code from the internet before trusting it."

pause

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
