#!/usr/bin/env bash

# Ensure we're running in a terminal
[ -t 0 ] || exit 1

# Array to store items
declare -a items
# Array to store selected state (0 = unselected, 1 = selected)
declare -a selected

# Hide cursor and clean up on exit
tput civis
trap 'tput cnorm; stty echo; echo' EXIT

# Save and modify terminal settings
exec </dev/tty
old_settings=$(stty -g)
stty -icanon -echo

# Ensure we restore terminal settings on exit
trap 'stty "$old_settings"; tput cnorm; echo' EXIT

current=0
debug_msg=""

# Function to read a key
read_key() {
    local key
    IFS= read -r -n1 key
    printf '%s' "$key"
}

# Default items if none provided
if [ $# -eq 0 ]; then
    items=(
        "Item 1"
        "Item 2"
        "Item 3"
        "Item 4"
        "Item 5"
    )
else
    items=("$@")
fi

# Initialize selection array with zeros
for ((i=0; i<${#items[@]}; i++)); do
    selected[$i]=0
done

# Debug message variable
debug_msg=""

# Function to draw the menu
draw_menu() {
    # Move cursor to top-left corner
    printf "\033[H"
    # Clear from cursor to end of screen
    printf "\033[J"
    
    printf "Use UP/DOWN arrows to move, SPACE to toggle, ENTER to finish, Q to quit\n"
    printf "%s\n" "----------------------------------------"
    
    # Draw each item
    for ((i=0; i<${#items[@]}; i++)); do
        # Prepare the checkbox
        local checkbox="[ ]"
        [ "${selected[$i]}" -eq 1 ] && checkbox="[x]"
        
        # If this is the current item, add highlighting
        if [ $i -eq $current ]; then
            printf "\033[7m%s %s\033[0m\n" "$checkbox" "${items[$i]}"
        else
            printf "%s %s\n" "$checkbox" "${items[$i]}"
        fi
    done
    printf "%s\n" "----------------------------------------"
    
}

# Main loop
while true; do
    draw_menu
    
    # Read key input
    key=$(read_key)
    
    # Handle the keypress
    case "$key" in
        " ")  # Space key
            selected[$current]=$((1 - ${selected[$current]}))
            ;;
        "")  # Enter key might come as empty on macOS
            # Clear screen first
            printf "\033[H\033[J"
            
            # Create an array of selected items
            selected_items=()
            for ((i=0; i<${#items[@]}; i++)); do
                [ ${selected[$i]} -eq 1 ] && selected_items+=("${items[$i]}")
            done
            
            # Output the list in a nice format
            if [ ${#selected_items[@]} -eq 0 ]; then
                printf "No items selected\n"
                # echo "No items selected"
            else
                # echo "Selected items:"
                printf "%s " "${selected_items[@]}"
                # echo "Total: ${#selected_items[@]} item(s)"
            fi
            
            # Make sure to exit
            stty "$old_settings"
            tput cnorm
            exit 0
            ;;
        'q'|'Q')  # Quit
            exit 0
            ;;
        $'\x1b')  # Escape sequence (arrow keys)
            read -rsn2 rest_key
            case "$rest_key" in
                '[A')  # Up arrow
                    ((current--))
                    [ $current -lt 0 ] && current=$((${#items[@]} - 1))
                    ;;
                '[B')  # Down arrow
                    ((current++))
                    [ $current -ge ${#items[@]} ] && current=0
                    ;;
            esac
            ;;
        'q'|'Q')  # Quit
            exit 0
            ;;
        *)
            : # Do nothing for other keys
            ;;
    esac
done
