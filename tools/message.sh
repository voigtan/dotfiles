#!/usr/bin/env zsh

ok() {
  echo "\e[0;32mOK\e[0m\t$1"
}

msg() {
  echo "\e[0;36m$1\e[0m\t"
}

warn() {
  echo "\e[0;33mWARN!\e[0m\t$1"
}

error_exit() {
  echo "\e[0;31mERROR!\e[0m\t$1"
  exit 1
}

pause() {
  read \?'Press any key to continue or Ctrl+C to exit...'
}

function banner() {
    color=36
    color2=35

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
