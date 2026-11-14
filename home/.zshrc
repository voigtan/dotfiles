# Set GPG TTY for the current interactive terminal/tmux pane
export GPG_TTY=$TTY

# Path to your oh-my-zsh installation.
DEFAULT_USER="$USER"
export ZSH="$HOME/.oh-my-zsh"

# Uncomment the following line to use case-sensitive completion.
CASE_SENSITIVE="false"

# Ensure Homebrew env & PATH are loaded even in non-login interactive shells
if [[ -z "$HOMEBREW_PREFIX" && -f "$HOME/.zprofile" ]]; then
    source "$HOME/.zprofile"
fi

# Add Homebrew Zsh completions to FPATH before Oh My Zsh runs compinit
if [[ -n "$HOMEBREW_PREFIX" ]]; then
    FPATH="$HOMEBREW_PREFIX/share/zsh-completions:$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"
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
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]] && source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]] && source "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

# Load custom zsh configurations (aliases, functions, etc.)
for file in ~/.config/zsh/*.zsh(N); do
    [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

# Prompt & directory jumper
(( $+commands[starship] )) && eval "$(starship init zsh)"
(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
