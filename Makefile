SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

USR          := $(shell id -un)
UID          := $(shell id -u)
GID          := $(shell id -g)
HOSTNAME_VAR := $(shell bash -lc 'echo $${USER:0:3}')

IMAGE     := z.ma/vcs-caliptra-centos:dev
CONTAINER := caliptra-$(USR)

HOST_REPO := $(CURDIR)
HOST_WS   := $(HOST_REPO)/ws
CONT_WS   := /home/usr/ws

X11_MOUNT := $(if $(wildcard /tmp/.X11-unix),-v /tmp/.X11-unix:/tmp/.X11-unix)
VCS_MOUNT := -v /tools/Syncopsys:/tools/Synopsys:ro

.PHONY: fresh restart image start enter kill

fresh: kill image start

restart: kill start

image:
	git submodule update --init --recursive
	docker build \
		-f Dockerfile \
		--build-arg UID=$(UID) \
		--build-arg GID=$(GID) \
		-t $(IMAGE) .

start:
	- xhost +Local:docker
	docker run -d --name $(CONTAINER) \
		-h $(HOSTNAME_VAR) \
		-e DISPLAY=$(DISPLAY) \
		--tty --interactive \
		$(X11_MOUNT) \
		$(VCS_MOUNT) \
		-v $(HOST_WS):$(CONT_WS) \
		-w $(CONT_WS) \
		$(IMAGE) tail -f /dev/null

enter:
	docker exec -it $(CONTAINER) bash -i

kill:
	- docker kill $(CONTAINER) || true
	- docker rm $(CONTAINER) || true
