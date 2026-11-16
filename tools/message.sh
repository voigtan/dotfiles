#!/usr/bin/env zsh

# @description Print a green success message.
# @arg $1 string Message text.
ok() {
    echo "\e[0;32mOK\e[0m\t$1"
}

# @description Print a cyan informational message.
# @arg $1 string Message text.
msg() {
    echo "\e[0;36m$1\e[0m\t"
}

# @description Print a yellow warning message.
# @arg $1 string Warning text.
warn() {
    echo "\e[0;33mWARN!\e[0m\t$1"
}

# @description Print a red error message and terminate the script.
# @arg $1 string Error message text.
# @exitcode 1 Always exits with status 1.
error_exit() {
    echo "\e[0;31mERROR!\e[0m\t$1"
    exit 1
}

# @description Pause execution until the user presses a key.
pause() {
    read \?'Press any key to continue or Ctrl+C to exit...'
}

# @description Print the dotfiles ASCII art banner.
banner() {
    local color=36
    local color2=35

    echo "\e[0;${color}m            .__        __ "
    echo "___  ______ |__| _____/  |______    ____ "
    echo "\  \/ /  _ \|  |/ ___\   __\__  \  /    \ "
    echo " \   (  <_> )  / /_/  >  |  / __ \|   |  \ "
    echo "  \_/ \____/|__\___  /|__| (____  /___|  /"
    echo "              /_____/ \e[0;${color2}m ┓   ┏•┓ \e[0;${color}m \/     \/ \e[0;${color2}m"
    echo "                      ┏┫┏┓╋╋┓┃┏┓┏"
    echo "                      ┗┻┗┛┗┛┗┗┗ ┛"
    echo "\e[0m"
}
