#!/usr/bin/env bash

# interactive_checklist: Present options and set the given output variable
# Usage:
#   options=("Label 1:val1" "Label 2:val2" ...)
#   interactive_checklist "${options[@]}" chosen
#   echo "Selected values: ${chosen[@]}"

interactive_checklist() {
    local -n _checklist_out="${@: -1}"
    local options=("${@:1:$#-1}")
    local labels=()
    local values=()
    local i

    _checklist_out=()

    # Split options into labels and values
    for opt in "${options[@]}"; do
        labels+=("${opt%%:*}")
        values+=("${opt#*:}")
    done

    if ! command -v fzf >/dev/null 2>&1; then
        echo "interactive_checklist requires fzf. Please install it first." >&2
        return 1
    fi

    # Prefix each label with its index so duplicate labels stay distinguishable
    local lines=""
    for i in "${!labels[@]}"; do
        lines+="${i}"$'\t'"${labels[i]}"$'\n'
    done

    local selected
    selected=$(printf "%s" "$lines" | fzf \
        --multi \
        --with-nth=2.. \
        --delimiter=$'\t' \
        --bind 'space:toggle' \
        --header 'SPACE: select/deselect, ENTER: accept, ESC: cancel' \
        --marker="✓" \
    )

    # If selection was cancelled
    if [ $? -ne 0 ] || [ -z "$selected" ]; then
        return 1
    fi

    # Map each selected index back to its value
    local idx
    while IFS=$'\t' read -r idx _; do
        _checklist_out+=("${values[idx]}")
    done <<< "$selected"
}


# Example usage (uncomment to test)
# options=("Label 1:val1" "Label 2:val2" "Label 3:val3" "Label 1:val1")
# interactive_checklist "${options[@]}" chosen
# echo "Selected values: ${chosen[@]}"