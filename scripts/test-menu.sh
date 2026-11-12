#!/usr/bin/env bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$dir/tools/menu.sh"
source "$dir/tools/interactive_checklist.sh"

options=("Alpha" "Beta" "Gamma" "Delta")

interactive_menu "${options[@]}" chosen
echo "Selected values: ${chosen[@]}"

options=("Label 1:Alpha" "Label 2:Beta" "Label 3:Gamma" "Label 1:Delta")
interactive_checklist "${options[@]}" chosen
echo "Selected values: ${chosen[@]}"