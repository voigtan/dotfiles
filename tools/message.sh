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