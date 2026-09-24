#!/usr/bin/env bash

CHECKLIST_SELECTED=()
interactive_checklist() {
    # Check if fzf is installed
    if ! command -v fzf >/dev/null 2>&1; then
        echo "This function requires fzf. Please install it first." >&2
        return 1
    fi

    local options=("$@")
    local labels=()
    local values=()
    local mapfile_tmp=$(mktemp)
    trap 'rm -f "$mapfile_tmp"' RETURN

    # Split options into labels and values
    for opt in "${options[@]}"; do
        label="${opt%%:*}"
        value="${opt#*:}"
        labels+=("$label")
        values+=("$value")
        echo "$label:$value" >> "$mapfile_tmp"
    done

    # Run fzf to select labels
    selected_labels=$(printf "%s\n" "${labels[@]}" | fzf \
        --multi \
        --bind 'k:accept' \
        --header 'TAB: select/deselect, k: accept, ESC: cancel' \
        --marker="✓" \
        --preview 'echo "Selected item"')

    # If selection was cancelled
    if [ $? -ne 0 ] || [ -z "$selected_labels" ]; then
        CHECKLIST_SELECTED=()
        return 1
    fi

    # Map selected labels back to values
    CHECKLIST_SELECTED=()
    while IFS= read -r label; do
        value=$(grep -F "${label}:" "$mapfile_tmp" | sed 's/^[^:]*://')
        CHECKLIST_SELECTED+=("$value")
    done <<< "$selected_labels"
}
# Example usage (uncomment to test)
# options=("First Option:one" "Second Option:two" "Third Option:three")
# interactive_checklist "${options[@]}"
# echo "Selected values: ${CHECKLIST_SELECTED[@]}"
#!/usr/bin/env bash

# Check if fzf is installed
if ! command -v fzf >/dev/null 2>&1; then
    echo "This script requires fzf. Please install it first."
    exit 1
fi

# Default items if none provided
default_items=(
    "Item 1"
    "Item 2"
    "Item 3"
    "Item 4"
    "Item 5"
)

# Use provided items or default ones
items=("${@:-${default_items[@]}}")

# Create a temporary file to store the selected items
tmp_file=$(mktemp)
trap 'rm -f "$tmp_file"' EXIT

# Print initial list to temp file
printf "%s\n" "${items[@]}" > "$tmp_file"

# Run fzf in multi-select mode
# - Press TAB to select/deselect items
# - Press k to finish and show selected items
# - Press ESC to cancel
selected=$(cat "$tmp_file" | fzf \
    --multi \
    --bind 'k:accept' \
    --header 'TAB: select/deselect, k: accept, ESC: cancel' \
    --marker="✓" \
    --preview 'echo "Selected item"')

# Check if selection was successful (k was pressed)
if [ $? -eq 0 ]; then
    echo -e "\nSelected items:"
    echo "$selected" | while read -r item; do
        echo "- $item"
    done
fi
