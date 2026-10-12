export GPG_TTY=$(tty)

# Path to your oh-my-zsh installation.
DEFAULT_USER="$(whoami)"
export ZSH="$HOME/.oh-my-zsh"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="false"

# Set up Homebrew Zsh completion if available
if type brew &>/dev/null; then
    FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH

    autoload -Uz compinit
    compinit
fi

# Which plugins would you like to load?
# Standard plugins can be found in ~/.oh-my-zsh/plugins/*
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
    git
    docker
    docker-compose
    wd
    fzf
)
source $ZSH/oh-my-zsh.sh

# NVM
export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && \. "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
source $(brew --prefix nvm)/nvm.sh

for file in ~/.{aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# fzf
# Enable using ALT(CMD)+C to CD into the selected directory and customize behaviour
# https://betterprogramming.pub/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d
bindkey "ç" fzf-cd-widget

export FZF_DEFAULT_OPTS="
    --bind '<:toggle-preview'
    --color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
    --info=inline
    --layout=reverse
    --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
    --preview-window=:hidden
    --prompt='∼ ' --pointer='▶' --marker='✓'"

export PATH="/usr/local/sbin:$PATH"
export PATH="/opt/homebrew/opt/openjdk@17/bin:$PATH"
# Add Homebrew curl to PATH
export PATH="/opt/homebrew/opt/curl/bin:$PATH"

# Make `git go` complete like `git switch`
_git_go() { _git_switch }

# Don't upgrade casks that manage their own updates (e.g. Chrome, Discord)
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

eval "$(starship init zsh)"
