#!/usr/bin/env bash

chmod +x scripts/*.sh

# Load each of the tools.
for file in ./tools/*; do
    [ -e "$file" ] || continue

    [[ $file == "./tools/scripts.sh" ]] && continue

    source $file
done
