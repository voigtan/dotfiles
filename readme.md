# Installation

Open the terminal and start with the steps:

1. If its a new installation of macOS run:
    `xcode-select --install`

1. Install the dotfiles and homebrew apps.

        ```git clone https://github.com/voigtan/dotfiles.git ~/.dotfiles
        cd ~/.dotfiles
        ./install.sh```

2. Configure iTerm2:
    * Open iTerm2.
    * Go to the Preferences (`⌘,`)
    * In the General tab, check `Load preferences from a custom folder or URL`.
    * Fill in: `~/.dotfiles/iterm2`.
    * Restart iTerm2.