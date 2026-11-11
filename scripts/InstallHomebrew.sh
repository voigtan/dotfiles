#!/usr/bin/env zsh

sudo_keepalive

if ! appExists brew; then
    msg "Installing Homebrew"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Re-warm sudo immediately because Homebrew's installer runs `sudo -k` on exit
    sudo -A -v 2>/dev/null || true

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

brew update --quiet || warn "brew update encountered a warning, continuing..."
if ! brew bundle --no-upgrade; then
    warn "Some Brewfile items failed to install. Continuing setup..."
fi
brew cleanup -s || true

ok "Homebrew packages installed successfully"
