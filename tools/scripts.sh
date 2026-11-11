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
