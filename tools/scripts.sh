#!/usr/bin/env zsh

# Guard so tools are only loaded once per shell session
[[ -n "${_DOTFILES_TOOLS_LOADED:-}" ]] && return 0
export _DOTFILES_TOOLS_LOADED=1

chmod +x ./tools/*.sh 2>/dev/null || true

# Load each of the tools
for file in ./tools/*.sh; do
    [[ -e "$file" ]] || continue
    [[ "$file" == "./tools/scripts.sh" ]] && continue
    source "$file"
done

# Prompt for sudo once and keep sudo alive (even if child installers like Homebrew run `sudo -k`)
function sudo_keepalive() {
    [[ -n "${_DOTFILES_SUDO_READY:-}" ]] && return 0

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

    # Create a temporary 0700 askpass script so if Homebrew's installer runs `sudo -k`
    # or `brew bundle` casks need sudo, it re-authenticates automatically without prompting again
    local askpass_script
    askpass_script=$(mktemp "${TMPDIR:-/tmp}/dotfiles-askpass.XXXXXX")
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
