for envfile in ~/dotfiles/env/*.sh; do
  source ${envfile}

export GPG_TTY=$(tty)
