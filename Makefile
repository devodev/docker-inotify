.PHONY: build push
SHELL := /bin/bash
ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

IMAGE := devodev/inotify
VERSION ?= 0.1.0

LONG_TAG  := $(subst $(eval) ,.,$(wordlist 1,3,$(subst ., ,$(VERSION:%=%))))
SHORT_TAG := $(subst $(eval) ,.,$(wordlist 1,2,$(subst ., ,$(VERSION:%=%))))

TAGS := $(LONG_TAG) $(SHORT_TAG) latest

build:
	@docker build $(TAGS:%=-t $(IMAGE):%) $(ROOT_DIR)

push: build
	@$(TAGS:%=docker push $(IMAGE):%;)
