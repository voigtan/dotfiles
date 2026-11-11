SHELL := /bin/zsh
RUN = source ./tools/scripts.sh && source

.PHONY: help
help:    ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/:.*##/;/' | column -t -s ";"

.PHONY: install
install: ## Full macOS bootstrap & setup
	@./install.sh

.PHONY: link
link:    ## Symlink dotfiles into ~/ via GNU Stow
	@$(RUN) ./scripts/LinkDotfiles.sh

.PHONY: brew
brew:    ## Install Homebrew & Brewfile packages
	@$(RUN) ./scripts/InstallHomebrew.sh

.PHONY: omz
omz:     ## Install Oh My Zsh
	@$(RUN) ./scripts/InstallOhMyZSH.sh

.PHONY: dock
dock:    ## Reset & configure macOS Dock items
	@$(RUN) ./scripts/CleanDock.sh

.PHONY: tweaks
tweaks:  ## Apply macOS system defaults & UI tweaks
	@$(RUN) ./scripts/tweaks.sh

.PHONY: gpg
gpg:     ## Configure GPG agent to use pinentry-mac
	@$(RUN) ./scripts/SetupPinentry.sh
