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
if ! brew bundle; then
    warn "Some Brewfile items failed to install (e.g. Mac App Store apps if not signed in yet). Continuing setup..."
fi
brew cleanup -s || true

# Verify Gatekeeper signature and clear quarantine flag on Homebrew-installed casks
# so macOS doesn't block or prompt on first launch after bulk installation
for cask_name in $(brew list --cask 2>/dev/null); do
    for app_path in /opt/homebrew/Caskroom/"$cask_name"/*/*.app(N); do
        app_name="${app_path:t}"
        target_app="/Applications/$app_name"
        if [[ -d "$target_app" ]] && xattr -p com.apple.quarantine "$target_app" >/dev/null 2>&1; then
            if spctl --assess --type execute "$target_app" >/dev/null 2>&1 || codesign --verify --deep --strict "$target_app" >/dev/null 2>&1; then
                sudo xattr -dr com.apple.quarantine "$target_app" 2>/dev/null || true
            fi
        fi
    done
done

ok "Homebrew packages installed successfully"
