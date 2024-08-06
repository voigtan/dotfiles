#!/usr/bin/env zsh

source ./tools/scripts.sh

# Define the folder containing the files to check
folder_path_dotfiles_home="home"

# if Stow is not installed, do not proceed
if ! appExists stow; then
  error_exit "Stow is not installed. Please install Stow before running this script."
fi

# Check if the folder exists
if [ ! -d "$folder_path_dotfiles_home" ]; then
  error_exit "Folder $folder_path_dotfiles_home does not exist."
fi

# msg "Setting up symlink of dotfiles"

# Loop through each dotfile in the folder
for file in "$folder_path_dotfiles_home"/.*(N); do
  # Ignore . and .. entries
  if [ "$file" = "$folder_path_dotfiles_home/." ] || [ "$file" = "$folder_path_dotfiles_home/.." ]; then
    continue
  fi

  # Extract the filename from the path
  filename="${file##*/}"

  # Check if the file is a symlink
  if [ -L ~/"$filename" ]; then
    # ok "~/$filename is a symlink, skipping"
    continue
  fi

  # Check if the file exists in the home directory
  if [ -e ~/"$filename" ]; then
    # Rename the existing file to <filename>.bak
    mv ~/"$filename" ~/"$filename".bak
    warn "↔️ Renamed ~/$filename to ~/$filename.bak"
  fi

done

stow home

ok "Dotfiles symlinked successfully"
