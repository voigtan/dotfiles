DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker} \
  && mkdir -p $DOCKER_CONFIG/cli-plugins \
  && curl -SL https://github.com/docker/compose/releases/download/v2.30.2/docker-compose-darwin-aarch64 -o $DOCKER_CONFIG/cli-plugins/docker-compose \
  && chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose \
  && docker compose version
