#!/usr/bin/env zsh

source ./tools/scripts.sh
# Setting up GPG to use pinentry-mac on macOS

# https://gist.github.com/troyfontaine/18c9146295168ee9ca2b30c00bd1b41e?permalink_comment_id=3660126
if appExists "brew" && ask "Want GPG to use pinentry-mac?" N; then

    if ! appExists "pinentry-mac"; then
        brew install pinentry-mac
        ok "pinentry-mac installed"
    fi

    # Check if the ~/.gnupg directory exists, if not, create it
    if [ ! -d "$HOME/.gnupg" ]; then
        warn ".gnupg missing... Creating empty folder"
        mkdir -p "$HOME/.gnupg"
        chmod 700 $HOME/.gnupg
    fi

    # Tell GPG to use pinentry-mac, and restart the agent.
    echo "pinentry-program $(brew --prefix)/bin/pinentry-mac" > ~/.gnupg/gpg-agent.conf

    gpgconf --kill gpg-agent

    ok "GPG configured to use pinentry-mac"
fi

exit 0
