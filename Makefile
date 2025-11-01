.PHONY: build-push build push
SHELL := /bin/bash
ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

IMAGE := devodev/inotify
VERSION ?= 0.4.0
PLATFORMS ?= linux/amd64,linux/arm64

LONG_TAG  := $(subst $(eval) ,.,$(wordlist 1,3,$(subst ., ,$(VERSION:%=%))))
SHORT_TAG := $(subst $(eval) ,.,$(wordlist 1,2,$(subst ., ,$(VERSION:%=%))))

TAGS := $(LONG_TAG) $(SHORT_TAG) latest

build-push:
	@docker buildx create --name multiarch-builder --driver=docker-container --platform $(PLATFORMS) --bootstrap || :
	@docker buildx build --builder multiarch-builder $(TAGS:%=-t $(IMAGE):%) --platform $(PLATFORMS) --push $(ROOT_DIR)
	@docker buildx rm multiarch-builder

# requires containerd image store enabled to build and push separately
# https://docs.docker.com/build/building/multi-platform/
build:
	@docker build $(TAGS:%=-t $(IMAGE):%) --platform $(PLATFORMS) $(ROOT_DIR)

push: build
	@$(TAGS:%=docker push $(IMAGE):%;)
