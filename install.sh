#!/usr/bin/env zsh

chmod +x scripts/*.sh tools/*.sh 2>/dev/null || true

source ./tools/scripts.sh
source ./scripts/Bootstrap.sh
