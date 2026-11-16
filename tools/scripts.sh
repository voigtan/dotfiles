#!/usr/bin/env zsh

# Guard so tools are only loaded once per shell session
if [[ -n "${_DOTFILES_TOOLS_LOADED:-}" ]]; then
    return 0
fi
export _DOTFILES_TOOLS_LOADED=1

chmod +x ./tools/*.sh 2>/dev/null || true

# Load each of the tools
for file in ./tools/*.sh; do
    if [[ ! -e "$file" || "$file" == "./tools/scripts.sh" ]]; then
        continue
    fi
    source "$file"
done
