#!/usr/bin/env zsh

# macOS-specific aliases and functions
if [[ $(uname -s) == 'Darwin' ]]; then
    # Add a spacer to the Dock
    alias separator='defaults write com.apple.dock persistent-apps -array-add "{"tile-type"="spacer-tile";}" && killall Dock'

    # Show/hide hidden files in Finder
    alias show="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hide="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"

    # Hide/show all desktop icons (useful when presenting)
    alias hidedesktop="defaults write com.apple.finder CreateDesktop -bool false && killall Finder"
    alias showdesktop="defaults write com.apple.finder CreateDesktop -bool true && killall Finder"

    # Google Chrome
    alias chrome='/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome'
    alias canary='/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary'
    alias chrome-extensions-disabled='open --new -a "Google Chrome" --args --disable-extensions'

    # Add a standard (d) or small (s) spacer tile to the macOS Dock
    # Usage: add-mac-space [s|d]
    add-mac-space() {
        local size=${1:-d}

        case "$size" in
            s)
                defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="small-spacer-tile";}'; killall Dock
                ;;
            d)
                defaults write com.apple.dock persistent-apps -array-add '{"tile-type"="spacer-tile";}'; killall Dock
                ;;
            *)
                echo "Usage: add-mac-space [s|d]"
                ;;
        esac
    }
fi
