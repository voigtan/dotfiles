#!/usr/bin/env zsh

# Open the dotfiles in Visual Studio Code
alias dotfiles='code ~/.dotfiles'

# Reload .zshrc
alias reload='. ~/.zshrc'

# Update cat, ls and mkdir to fit my needs
alias cat='bat -p'
alias ls='lsd --long --git --header --all'
alias mkdir='mkdir -p'

# Non-macOS `open` fallbacks
if [[ $(uname -s) != 'Darwin' ]]; then
	if grep -q Microsoft /proc/version 2>/dev/null; then
		# Ubuntu on Windows using the Linux subsystem
		alias open='explorer.exe'
	else
		alias open='xdg-open'
	fi
fi

# Override vim with nvim
alias vim='nvim'
alias nvim-voigtan="NVIM_APPNAME=nvim-voigtan nvim"

# Get week number
alias week='date +%V'

# IP addresses
alias ip="dig +short myip.opendns.com @resolver1.opendns.com"
alias localip="ipconfig getifaddr en0"
alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
