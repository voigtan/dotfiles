DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker} \
  && mkdir -p $DOCKER_CONFIG/cli-plugins \
  && ln -sfn $(brew --prefix)/opt/docker-compose/bin/docker-compose ~/.docker/cli-plugins/docker-compose \
  && ln -sfn $(brew --prefix)/opt/docker-buildx/bin/docker-buildx ~/.docker/cli-plugins/docker-buildx
