#!/usr/bin/env zsh

if ! appExists brew; then
    msg "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Setup Homebrew envvars
    if [[ $(arch) == "arm64" ]]; then
        if ! grep -qs '/opt/homebrew/bin/brew shellenv' ~/.zprofile 2>/dev/null; then
            (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
        fi
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ $(arch) == "i386" ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        error_exit "Invalid CPU arch: $(arch)" >&2
    fi

    ok "Homebrew installed"
else
    ok "Homebrew already installed"
fi

brew update --quiet && brew bundle && brew cleanup -s

ok "Homebrew packages installed successfully"
