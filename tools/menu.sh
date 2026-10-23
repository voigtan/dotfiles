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
    if (( $# == 0 )); then
        printf 'interactive_menu: expected an output variable name\n' >&2
        return 2
    fi

    local _menu_output_name="${!#}"
    case $_menu_output_name in
        ''|[!a-zA-Z_]*|*[!a-zA-Z0-9_]*)
            printf 'interactive_menu: output variable name must be a valid identifier\n' >&2
            return 2
            ;;
    esac

    local options=("${@:1:$#-1}")
    local count=${#options[@]}
    # Bash 3.2 lacks namerefs, so validate the target name and quote values before eval.
    eval "$_menu_output_name=()"
    (( count == 0 )) && return 1

    local cursor=0
    local checked=()
    local i key seq _menu_quoted selected_count=0
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
        if (( checked[i] == 1 )); then
            printf -v _menu_quoted '%q' "${options[i]}"
            eval "$_menu_output_name+=( $_menu_quoted )"
            selected_count=$((selected_count + 1))
        fi
    done
    if (( selected_count == 0 )); then
        printf -v _menu_quoted '%q' "${options[cursor]}"
        eval "$_menu_output_name+=( $_menu_quoted )"
    fi
}

# Example usage (uncomment to test)
# options=("First Option" "Second Option" "Third Option")
# interactive_menu "${options[@]}" chosen
# echo "Selected values: ${chosen[@]}"
