#!/usr/bin/env bash

# interactive_menu: keyboard-navigable list picker, no external dependencies.
# Usage:
#   options=("Option 1" "Option 2" "Option 3")
#   interactive_menu "${options[@]}" chosen
#   echo "Selected: ${chosen[@]}"
#
# Controls:
#   Up/Down or k/j : move cursor
#   Space          : toggle selection (multi-select)
#   Enter          : confirm (if nothing was toggled, selects the current item)
#   q / Esc        : cancel (output variable is emptied, returns 1)

# Renders the option list; relies on bash dynamic scoping to see the
# caller's locals (options, count, cursor, checked).
_interactive_menu_render() {
    local i mark
    for ((i = 0; i < count; i++)); do
        mark=" "
        (( checked[i] == 1 )) && mark="x"
        if (( i == cursor )); then
            printf "\033[7m> [%s] %s\033[0m\n" "$mark" "${options[i]}" > /dev/tty
        else
            printf "  [%s] %s\n" "$mark" "${options[i]}" > /dev/tty
        fi
    done
}

interactive_menu() {
    local -n _menu_out="${@: -1}"
    local options=("${@:1:$#-1}")
    local count=${#options[@]}
    _menu_out=()
    (( count == 0 )) && return 1

    local cursor=0
    local checked=()
    local i key seq
    for ((i = 0; i < count; i++)); do checked[i]=0; done

    printf "↑/k ↓/j move   space toggle   enter confirm   q/esc cancel\n" > /dev/tty
    tput civis > /dev/tty
    trap 'tput cnorm > /dev/tty' RETURN

    _interactive_menu_render
    while true; do
        IFS= read -rsn1 key < /dev/tty
        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.01 seq < /dev/tty
                case "$seq" in
                    '[A') (( cursor = (cursor - 1 + count) % count )) ;;
                    '[B') (( cursor = (cursor + 1) % count )) ;;
                    '')
                        printf "\033[%dA\033[J" "$((count + 1))" > /dev/tty
                        return 1
                        ;;
                esac
                ;;
            k) (( cursor = (cursor - 1 + count) % count )) ;;
            j) (( cursor = (cursor + 1) % count )) ;;
            ' ') (( checked[cursor] = 1 - checked[cursor] )) ;;
            q)
                printf "\033[%dA\033[J" "$((count + 1))" > /dev/tty
                return 1
                ;;
            '') break ;; # Enter
        esac
        printf "\033[%dA" "$count" > /dev/tty
        _interactive_menu_render
    done

    printf "\033[%dA\033[J" "$((count + 1))" > /dev/tty

    for ((i = 0; i < count; i++)); do
        (( checked[i] == 1 )) && _menu_out+=("${options[i]}")
    done
    (( ${#_menu_out[@]} == 0 )) && _menu_out=("${options[cursor]}")
}

# Example usage (uncomment to test)
# options=("First Option" "Second Option" "Third Option")
# interactive_menu "${options[@]}" chosen
# echo "Selected values: ${chosen[@]}"
