#!/usr/bin/env zsh

# @description Prompt the user with a yes/no question via /dev/tty.
# @arg $1 string Question prompt text.
# @arg $2 string Optional default answer ("Y" or "N").
# @exitcode 0 If the user answers yes.
# @exitcode 1 If the user answers no.
ask() {
    local prompt default REPLY

    while true; do
        if [[ "${2:-}" == "Y" ]]; then
            prompt="Y/n"
            default="Y"
        elif [[ "${2:-}" == "N" ]]; then
            prompt="y/N"
            default="N"
        else
            prompt="y/n"
            default=""
        fi

        echo -n "$1 [$prompt] "
        read -r REPLY </dev/tty

        if [[ -z "$REPLY" ]]; then
            REPLY="$default"
        fi

        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
    done
}
