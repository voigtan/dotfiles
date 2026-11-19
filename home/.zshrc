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

# History configuration
export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
export HISTSIZE=100000
export SAVEHIST=100000

setopt APPEND_HISTORY          # append to history file instead of overwriting
setopt SHARE_HISTORY           # share history across all open terminal sessions immediately
setopt HIST_IGNORE_DUPS        # do not record a command just run again
setopt HIST_IGNORE_ALL_DUPS    # remove older duplicate entry if a new command is a duplicate
setopt HIST_IGNORE_SPACE       # do not record commands starting with a leading space
setopt HIST_EXPIRE_DUPS_FIRST  # expire duplicate entries first when trimming history
setopt HIST_FIND_NO_DUPS       # do not display duplicates when searching history
setopt HIST_REDUCE_BLANKS      # strip unnecessary blanks before recording a command

# Shell options
setopt AUTOCD                  # cd into a directory simply by typing its name
setopt NOBEEP                  # disable terminal bell on errors or tab-completion
setopt NUMERIC_GLOB_SORT       # sort file10 after file9, not after file1
[[ -t 0 ]] && stty discard undef 2>/dev/null # prevent macOS TTY from swallowing Ctrl+O (^O)


# NVM
export NVM_DIR="$HOME/.nvm"
[[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]] && source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]] && source "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

# Load custom zsh configurations (aliases, functions, etc.)
for file in ~/.config/zsh/*.zsh(N); do
    [[ -r "$file" && -f "$file" ]] && source "$file"
done
unset file

# Prompt & directory jumper (`cd` / `cdi` + `z` / `zi` aliases)
(( $+commands[starship] )) && eval "$(starship init zsh)"
if (( $+commands[zoxide] )); then
    eval "$(zoxide init --cmd cd zsh)"
    alias z='cd'
    alias zi='cdi'
fi
