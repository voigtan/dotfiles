#!/usr/bin/env zsh

# Define the folder containing the files to check
folder_path_dotfiles_home="home"

# if Stow is not installed, do not proceed
if ! appExists stow; then
	warn "stow is not installed. Please install stow before running this script."

	if appExists "brew" && ask "Do you want to download stow?" N; then
		brew install stow
		ok "stow installed"
	else
		error_exit "stow is required to run this script. Please install stow and run this script again."
	fi
fi

# Check if the folder exists
if [ ! -d "$folder_path_dotfiles_home" ]; then
  error_exit "Folder $folder_path_dotfiles_home does not exist."
fi

# Remove any macOS .DS_Store files inside home/ so Stow never conflicts on them
find "$folder_path_dotfiles_home" -name ".DS_Store" -delete

# Automatically create top-level hidden directories (e.g. ~/.config, ~/.colima, ~/.docker)
# and any intermediate container directories that hold only subdirectories (no direct files),
# so Stow links individual config folders/files instead of folding the root directory.
for dir in "$folder_path_dotfiles_home"/**/*(ND/); do
  rel_dir="${dir#${folder_path_dotfiles_home}/}"

  # Skip if already a symlink in $HOME
  [[ -L ~/"$rel_dir" ]] && continue

  # Always create top-level hidden directories in $HOME (depth 1, e.g. .config, .colima, .docker)
  if [[ "${dir:h}" == "$folder_path_dotfiles_home" ]]; then
    mkdir -p ~/"$rel_dir"
    continue
  fi

  # For deeper directories, only mkdir -p if neither this directory nor any of its
  # depth >= 2 ancestors has direct files (meaning it's purely a container path like .config/opencode)
  check_dir="$dir"
  has_package_files=false
  while [[ "${check_dir:h}" != "$folder_path_dotfiles_home" && "$check_dir" != "/" ]]; do
    direct_files=("$check_dir"/*(ND.))
    if (( ${#direct_files} > 0 )); then
      has_package_files=true
      break
    fi
    check_dir="${check_dir:h}"
  done

  if ! $has_package_files; then
    mkdir -p ~/"$rel_dir"
  fi
done

# Back up any conflicting regular files in $HOME before running Stow
for file in "$folder_path_dotfiles_home"/**/*(ND.); do
  rel_path="${file#${folder_path_dotfiles_home}/}"
  target=~/"$rel_path"

  # Skip if the file or any of its parent directories in $HOME is already a symlink
  curr="$target"
  is_linked=false
  while [[ "$curr" != "$HOME" && "$curr" != "/" ]]; do
    if [[ -L "$curr" ]]; then
      is_linked=true
      break
    fi
    curr="${curr:h}"
  done
  $is_linked && continue

  if [[ -f "$target" ]]; then
    mv "$target" "${target}.bak"
    warn "↔️ Renamed ~/$rel_path to ~/${rel_path}.bak"

    # If the parent directory in $HOME is now empty, remove it so Stow can fold the directory cleanly
    parent_dir="${target:h}"
    if [[ "$parent_dir" != "$HOME" && -d "$parent_dir" && ! -L "$parent_dir" ]]; then
      remaining=("$parent_dir"/*(ND))
      if (( ${#remaining} == 0 )); then
        rmdir "$parent_dir"
      fi
    fi
  fi
done

stow home

ok "Dotfiles symlinked successfully"
