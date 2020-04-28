# Standard settings that will be used later
DOCKER             := $(shell which docker)
COMPOSE            := $(shell which docker-compose)
SHA1               := $(shell git rev-parse --short HEAD)
BRANCH             := $(shell basename $(shell git symbolic-ref HEAD))
DOCKER_TAG         ?= ${SHA1}
DOCKER_IMAGE       ?= $(shell basename $(CURDIR) .git)
DOCKER_REGISTRY    ?= hub.corp.nextdoor.com
DOCKER_NAMESPACE   ?= nextdoor
LOCAL_DOCKER_NAME  := "${DOCKER_IMAGE}:${SHA1}"
TARGET_DOCKER_NAME := "${DOCKER_REGISTRY}/${DOCKER_NAMESPACE}/${DOCKER_IMAGE}:${DOCKER_TAG}"

docker_login:
	@echo "Logging into ${DOCKER_REGISTRY}"
	@$(DOCKER) login \
		-u '${DOCKER_USER}' \
		-p '$(value DOCKER_PASS)' '${DOCKER_REGISTRY}'

docker_populate_cache:
	@echo "Attempting to download ${DOCKER_IMAGE}"
	@$(DOCKER) pull "${DOCKER_REGISTRY}/${DOCKER_IMAGE}" && \
	      	$(DOCKER) images -a || exit 0

docker_build:
	@echo "Building ${LOCAL_DOCKER_NAME}"
	@$(DOCKER) build -t "${LOCAL_DOCKER_NAME}" .

docker_tag: docker_build
	@echo "Tagging ${LOCAL_DOCKER_NAME} as ${TARGET_DOCKER_NAME}"
	@$(DOCKER) tag \
		"${LOCAL_DOCKER_NAME}" \
		"${TARGET_DOCKER_NAME}"

docker_push: docker_tag
	@echo "Pushing ${LOCAL_DOCKER_NAME} to ${TARGET_DOCKER_NAME}"
	@$(DOCKER) push "${TARGET_DOCKER_NAME}"
