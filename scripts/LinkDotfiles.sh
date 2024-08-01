#!/bin/bash

# Define the folder containing the files to check
folder_path="home"

# Check if the folder exists
if [ ! -d "$folder_path" ]; then
  echo "Folder $folder_path does not exist."
  exit 1
fi

# Print the content of the folder for debugging
echo "Listing files in $folder_path:"
ls -la "$folder_path"

# Loop through each file in the folder, including hidden files
files=("$folder_path"/.* "$folder_path"/*)

# Remove the entries for . and .. directories
files=("${files[@]##*/}")

# Check if the array contains files
if [ ${#files[@]} -eq 0 ] || [ \( ${#files[@]} -eq 2 -a "${files[0]}" == "." -a "${files[1]}" == ".." \) ]; then
  echo "No files found in $folder_path."
  exit 1
fi

for file in "${files[@]}"; do
  # Ignore . and .. entries
  if [ "$file" == "." ] || [ "$file" == ".." ]; then
    continue
  fi

  # Extract the filename from the path
  filename=$(basename "$file")

  echo "Checking $filename"
  
  # Check if the file exists in the home directory and is not a symlink
  if [ -e ~/"$filename" ] && [ ! -L ~/"$filename" ]; then
    # Rename the existing file to <filename>.bak
    mv ~/"$filename" ~/"$filename".bak
    echo "Renamed ~/$filename to ~/$filename.bak"
  elif [ -L ~/"$filename" ]; then
    echo "~/$filename is a symlink, skipping"
  fi
done

# Add your stow command here
stow home