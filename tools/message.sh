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
