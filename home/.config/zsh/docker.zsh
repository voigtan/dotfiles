#!/usr/bin/env zsh

# Remove all Docker Images
alias dcr-ri='docker rmi $(docker images -a -q)'

# Remove all exited Docker Containers
alias dcr-rc='docker rm $(docker ps -a -f status=exited -q)'

# Formatted Docker container list
alias dcr-ps='docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}\t{{.Ports}}"'

# Lazydocker shortcut
alias lzd='lazydocker'

# Interact with a running Docker container
# Usage: dockerInteract <container_id>
dockerInteract() {
    docker exec -it $1 sh
}
