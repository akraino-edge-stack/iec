# build image for apiserver

# This image is built from files in this directory and pushed to
# a docker registry that is accesseble on each node.
#
#

# For a user created registry, the registry must be setup ahead of time.
# This Makefile supports both amd64 and arm64

EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
COMMA := $(EMPTY),$(EMPTY)

DOCKER ?= docker
LINUX_ARCH := amd64 arm64
ARCHES = amd64 arm64
DOCKERFILE :=
REGISTRY ?= iecedge
PLATFORMS := $(subst $(SPACE),$(COMMA),$(foreach arch,$(LINUX_ARCH),linux/$(arch)))

# SECRET is used when pushing the manifest. docker-credential-gcr may not be
# available locally (except in Jenkins) so delay the evaluation unless the secret
# is needed.
SECRET = $(shell echo "https://gcr.io" | docker-credential-gcr get | jq '.Secret')

BUILD_ARCH ?= $(shell [ $$(uname -m) = "aarch64" ] && echo "arm64" || echo "amd64")
IMAGE_BASE ?= $(REGISTRY)/iec-apiserver-base-$(BUILD_ARCH)

TAG ?= latest
GIT_VERSION ?= $(shell git describe --always --dirty --tags)
IMAGE_VERSION ?= $(GIT_VERSION)
IMAGE_TAG := $(shell echo $(IMAGE_VERSION) | cut -d. -f1,2)
IMAGE_BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD | tr -d '/')

#Currently, we choose golang-alpine based image as the default image base due to its 
#small size
base:
	@IMAGE_NAME="$(REGISTRY)/iec-apiserver-base"; \
	docker build -t $$IMAGE_NAME-$(BUILD_ARCH) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_VERSION) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_TAG) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_BRANCH) \
	            -f docker/Dockerfile.base \
		      .

#Use native golang based image as the base of apiserver, the reason to keep it here
#is that it is easier to extend if we need to add extra functions into it.
#It's kept here as a backup.
base-golang:
	@IMAGE_NAME="$(REGISTRY)/iec-apiserver-base"; \
	docker build -t $$IMAGE_NAME-$(BUILD_ARCH)-golang \
		    -t $$IMAGE_NAME-$(BUILD_ARCH)-golang:$(IMAGE_VERSION) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH)-golang:$(IMAGE_TAG) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH)-golang:$(IMAGE_BRANCH) \
	            -f docker/Dockerfile.base.golang \
		    .

.PHONY: apiserver
apiserver:
	@IMAGE_NAME="$(REGISTRY)/iec-apiserver"; \
	docker build -t $$IMAGE_NAME-$(BUILD_ARCH) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_VERSION) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_TAG) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_BRANCH) \
		    --build-arg IMAGEBASE="${IMAGE_BASE}" \
	            -f docker/Dockerfile \
		       .

#Use golang image as the base, but only used as a backup now
.PHONY: apiserver-golang
apiserver-golang:
	@IMAGE_NAME="$(REGISTRY)/iec-apiserver"; \
	docker build -t $$IMAGE_NAME-$(BUILD_ARCH)-golang \
		    -t $$IMAGE_NAME-$(BUILD_ARCH)-golang:$(IMAGE_VERSION) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH)-golang:$(IMAGE_TAG) \
		    -t $$IMAGE_NAME-$(BUILD_ARCH)-golang:$(IMAGE_BRANCH) \
		    --build-arg IMAGEBASE="${IMAGE_BASE}"-golang \
	            -f docker/Dockerfile.golang \
		       .


all: base apiserver

#Before push images or push fat-manifest, please use 'docker login -u your_repo_account' to login to dockerhub first
#For docker login, it may need to install package 'jq', like "sudo apt-get install -y jq" for Debian based system

push_images:
	@IMAGE_NAME="$(REGISTRY)/iec-apiserver-base"; \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_VERSION); \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_TAG); \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_BRANCH); \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(TAG)

	@IMAGE_NAME="$(REGISTRY)/iec-apiserver"; \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_VERSION); \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_TAG); \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(IMAGE_BRANCH); \
	docker push $$IMAGE_NAME-$(BUILD_ARCH):$(TAG);

.PHONY: pre_manifest
pre_manifest:
	if [ ! -f "./manifest-tool" ]; then \
		wget https://github.com/estesp/manifest-tool/releases/download/v0.9.0/manifest-tool-linux-$(BUILD_ARCH) \
	  	-O manifest-tool && \
  	 	chmod +x ./manifest-tool; \
	fi

.push_manifest: pre_manifest
	./manifest-tool push from-args --platforms $(PLATFORMS) --template $(REGISTRY)/$(TARGET)-ARCH:$(VERSION) --target $(REGISTRY)/$(TARGET):$(VERSION)


#Note: Currently, just multi-arch the latest version of the images to avoid the possible version 
#mismatch between amd64 and arm64 in docker hub. In case we need them, we can just remove the comment tags below
#Just multi-arch the iec-apiserver image currently

multi_arch:
	#$(MAKE) .push_manifest VERSION=$(TAG) TARGET="iec-apiserver-base"
	$(MAKE) .push_manifest VERSION=$(TAG) TARGET="iec-apiserver"

push: pre_manifest push_images multi_arch
	#$(MAKE) .push_manifest VERSION=$(IMAGE_VERSION) TARGET="iec-apiserver-base"
	#$(MAKE) .push_manifest VERSION=$(IMAGE_TAG) TARGET="iec-apiserver-base"
	#$(MAKE) .push_manifest VERSION=$(IMAGE_VERSION) TARGET="iec-apiserver"
	#$(MAKE) .push_manifest VERSION=$(IMAGE_TAG) TARGET="iec-apiserver"

#For cleaning images, it seems more stable when we remove it by their names, not just by their ids.
clean_image:
	#$(DOCKER) rmi -f `$(DOCKER) images $(REGISTRY)/$(TARGET) -a -q` || true
	$(DOCKER) rmi -f $(REGISTRY)/$(TARGET):$(VERSION) || true

#Normally, we don't remove the base image to keep a stable Revel version for use
clean:
	docker rmi $(docker images --filter "dangling=true" -q --no-trunc) || true
	#$(MAKE) clean_image TARGET=iec-apiserver-base-$(BUILD_ARCH) VERSION=$(IMAGE_VERSION)
	#$(MAKE) clean_image TARGET=iec-apiserver-base-$(BUILD_ARCH) VERSION=$(IMAGE_TAG)
	#$(MAKE) clean_image TARGET=iec-apiserver-base-$(BUILD_ARCH) VERSION=$(IMAGE_BRANCH)
	#$(MAKE) clean_image TARGET=iec-apiserver-base-$(BUILD_ARCH) VERSION=$(TAG)

	$(MAKE) clean_image TARGET=iec-apiserver-$(BUILD_ARCH) VERSION=$(IMAGE_VERSION)
	$(MAKE) clean_image TARGET=iec-apiserver-$(BUILD_ARCH) VERSION=$(IMAGE_TAG)
	$(MAKE) clean_image TARGET=iec-apiserver-$(BUILD_ARCH) VERSION=$(IMAGE_BRANCH)
	$(MAKE) clean_image TARGET=iec-apiserver-$(BUILD_ARCH) VERSION=$(TAG)
