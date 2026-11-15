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

# Show a live directory tree preview when using zoxide's interactive picker (`zi` / `cdi`)
export _ZO_FZF_OPTS="
    --height=65%
    --layout=reverse
    --border=rounded
    --info=inline
    --preview='lsd --tree --depth=2 --color=always --icon=always {2..} 2>/dev/null || tree -C -L 2 {2..} 2>/dev/null'
    --preview-window=right:50%:border-left"

# Sync & boost `wd` warp points (~/.warprc) into zoxide so bookmarked folders rank at the top
zoxide-sync-wd() {
    (( $+commands[zoxide] )) || return 0
    [[ -f "$HOME/.warprc" ]] || return 0

    local line raw_path expanded_path
    local -a paths=()
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        raw_path="${line#*:}"
        expanded_path="${raw_path/#\~/$HOME}"
        [[ -d "$expanded_path" ]] && paths+=("$expanded_path")
    done < "$HOME/.warprc"

    (( ${#paths[@]} > 0 )) && zoxide add --score 100 "${paths[@]}"
}

# Automatically boost zoxide score whenever a new warp point is added via `wd add`
if (( $+functions[wd] )); then
    functions[_orig_wd]="${functions[wd]}"
    wd() {
        _orig_wd "$@"
        local ret=$?
        if (( ret == 0 && $+commands[zoxide] )); then
            case "${1:-}" in
                add|addcd)
                    zoxide add --score 100 "${2:-$PWD}" 2>/dev/null
                    ;;
            esac
        fi
        return $ret
    }
fi
