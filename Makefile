.PHONY: help
help:    ## Show this help.
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/:.*##/;/' | column -t -s ";"

.PHONY: install
install: ## Install dependencies
	@./install.sh
