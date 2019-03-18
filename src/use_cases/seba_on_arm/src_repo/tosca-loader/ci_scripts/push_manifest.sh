export IMAGE_TAG=$(cat VERSION)
export DOCKER_CLI_EXPERIMENTAL=enabled

docker manifest create --amend cachengo/xos-tosca:$IMAGE_TAG cachengo/xos-tosca-x86_64:$IMAGE_TAG cachengo/xos-tosca-aarch64:$IMAGE_TAG
docker manifest push cachengo/xos-tosca:$IMAGE_TAG

docker manifest create --amend cachengo/tosca-loader:$IMAGE_TAG cachengo/tosca-loader-x86_64:$IMAGE_TAG cachengo/tosca-loader-aarch64:$IMAGE_TAG
docker manifest push cachengo/tosca-loader:$IMAGE_TAG
