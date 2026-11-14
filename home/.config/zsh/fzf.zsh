#!/usr/bin/env zsh

# Enable using ALT(CMD)+C to CD into the selected directory and customize behaviour
# https://betterprogramming.pub/boost-your-command-line-productivity-with-fuzzy-finder-985aa162ba5d
bindkey "ç" fzf-cd-widget

export FZF_DEFAULT_OPTS="
    --bind '<:toggle-preview'
    --color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
    --info=inline
    --layout=reverse
    --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | less)) || echo {} 2> /dev/null | head -200'
    --preview-window=:hidden
    --prompt='∼ ' --pointer='▶' --marker='✓'"
