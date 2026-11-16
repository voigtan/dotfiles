#!/usr/bin/env zsh

# @description Prompt for the administrator password once, configure SUDO_ASKPASS,
#   and keep the sudo timestamp alive in the background until the script exits.
# @set SUDO_ASKPASS string Path to the temporary askpass helper script.
# @set _DOTFILES_SUDO_READY int Guard flag set to 1 once initialized.
# @set _DOTFILES_SUDO_PID int PID of the background keepalive loop.
sudo_keepalive() {
    if [[ -n "${_DOTFILES_SUDO_READY:-}" ]]; then
        return 0
    fi

    local sudo_pw
    while true; do
        printf "🔐 Administrator password: "
        read -rs sudo_pw
        echo ""
        if printf '%s\n' "$sudo_pw" | sudo -S -v 2>/dev/null; then
            break
        fi
        warn "Incorrect password, please try again."
    done

    # Create a temporary 0700 askpass script in /tmp so Homebrew's filtered environment
    # and root `sudo -A` subprocesses (like .pkg cask installers) can execute it cleanly
    local askpass_script
    askpass_script=$(mktemp "/tmp/dotfiles-askpass.XXXXXX")
    chmod 700 "$askpass_script"
    cat > "$askpass_script" <<EOF
#!/bin/sh
printf '%s\n' '${sudo_pw//\'/\'\\\'\'}'
EOF
    unset sudo_pw

    export SUDO_ASKPASS="$askpass_script"
    export _DOTFILES_SUDO_READY=1

    # Refresh sudo every 30s (using -A with SUDO_ASKPASS if `sudo -k` wiped the token)
    (
        while true; do
            sudo -n true 2>/dev/null || sudo -A -v 2>/dev/null || true
            sleep 30
            kill -0 "$$" 2>/dev/null || exit
        done
    ) >/dev/null 2>&1 &
    export _DOTFILES_SUDO_PID=$!

    trap 'rm -f "$SUDO_ASKPASS"; kill "$_DOTFILES_SUDO_PID" 2>/dev/null || true' EXIT INT TERM
}
