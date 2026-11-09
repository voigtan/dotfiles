# Installation

1. Clone the repository into `~/.dotfiles`:

```zsh
git clone https://github.com/voigtan/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

> **Note:** On a brand-new Mac without `git` or `make` yet, running `git clone` will automatically prompt macOS to install Xcode Command Line Tools (or `scripts/osx.sh` will install them automatically if you run `./install.sh`).

2. *(Optional)* Create `home/.extra` for local overrides (such as Git credentials):

```zsh
# Git credentials
GIT_AUTHOR_NAME=""
GIT_AUTHOR_EMAIL=""
GIT_SIGNINGKEY=""
```

3. Run the installer (installs Xcode CLI Tools, Oh My Zsh, Homebrew + `brewfile` packages/fonts, symlinks `home/` via GNU Stow, configures Ghostty/iTerm2/Dock/macOS defaults, and sets up `pinentry-mac`):

```zsh
make install
```

2. Configure iTerm2:
    * Open iTerm2.
    * Go to the Preferences (`⌘,`)
    * In the General tab, check `Load preferences from a custom folder or URL`.
    * Fill in: `~/.dotfiles/iterm2`.
    * Restart iTerm2.
