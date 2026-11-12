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

real_brewfile_groups=()
for file in ~/.dotfiles/brewfiles/Brewfile.*; do
    if [[ "$file" == *"Brewfile.ignore" ]]; then
        continue
    fi
    group=$(basename "$file" | cut -d. -f2)
    real_brewfile_groups+=("$group")
done

brew_groups=("${real_brewfile_groups[@]}")
selected_groups=("${brew_groups[@]}")

if [[ -n "${HOMEBREW_BREW_GROUPS:-}" ]]; then
    selected_groups=(${=HOMEBREW_BREW_GROUPS})
elif [[ -t 0 || -t 1 ]]; then
    msg "Select Brewfile groups to install:"
    if ! interactive_menu --all "${brew_groups[@]}" selected_groups; then
        warn "Brewfile selection cancelled, skipping package installation."
        selected_groups=()
    fi
fi

if (( ${#selected_groups[@]} > 0 )); then
    msg "Installing Brewfile groups: ${selected_groups[*]}"
    HOMEBREW_BREW_GROUPS="${selected_groups[*]}" brew bundle --no-upgrade || warn "Some Brewfile items failed to install. Continuing setup..."
else
    warn "No Brewfile groups selected."
fi

brew cleanup -s || true

ok "Homebrew packages installed successfully"
