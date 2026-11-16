# Deduplicate PATH and FPATH entries automatically
typeset -U path PATH fpath FPATH

# Initialize Homebrew (portable across Apple Silicon and Intel Macs)
if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Don't upgrade casks that manage their own updates (e.g. Chrome, Discord)
export HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1

# Prepend existing directories to PATH (silently skipped if not installed)
path=(
    "$HOME/.local/bin"(N-/)
    "${HOMEBREW_PREFIX}/opt/curl/bin"(N-/)
    "${HOMEBREW_PREFIX}/share/google-cloud-sdk/bin"(N-/)
    /usr/local/sbin(N-/)
    $path
)

export PATH

# Prepend Homebrew Zsh completions to FPATH (silently skipped if not installed)
fpath=(
    "${HOMEBREW_PREFIX}/share/zsh-completions"(N-/)
    "${HOMEBREW_PREFIX}/share/zsh/site-functions"(N-/)
    $fpath
)

export FPATH

