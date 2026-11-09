#!/usr/bin/env zsh

# Launch lazygit and change directory if a new directory is specified
# Usage: lg [options]
lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
        cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
        rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

# Show git diff with bat highlighting
# Usage: batdiff
batdiff() {
    git diff --name-only --diff-filter=d | xargs bat --diff
}

# Git wrapper that shows alias definition on `git <alias> --help` or `-h`
git() {
    if command git config --get "alias.$1" >/dev/null 2>&1; then
        local arg

        for arg in "$@"; do
            if [[ $arg == "--help" || $arg == "-h" ]]; then
                command git "$1" --info
                return
            fi
        done
    fi
    command git "$@"
}
