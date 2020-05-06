NAME = nmos-cpp
# grab the abrev commit SHA from Dockerfile
VERSION = 0.1S-$(shell sed -n 's/.*NMOS_CPP_VERSION=\(.......\).*/\1/p' Dockerfile)
# Get number of processors available and add 1
NPROC = $(shell echo $(shell nproc)+1 | bc)

.PHONY: all version build run save test tag_latest clean-docker-stopped-containers clean-docker-untagged-images

all: build

version:
	@echo Docker image version: $(VERSION)

build: version
	docker build -t $(NAME):$(VERSION) --build-arg makemt=$(NPROC) .

buildx: version
	docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t rhastie/$(NAME):$(VERSION) --build-arg makemt=$(NPROC) --push .

run: build
	docker run -d -it --net=host --name $(NAME)-registry --rm $(NAME):$(VERSION)

runnode: build
	docker run -d -it --net=host -e RUN_NODE=TRUE --name $(NAME)-node --rm $(NAME):$(VERSION)

start: run
	docker attach $(NAME)-registry

startnode: runnode
	docker attach $(NAME)-node

log:
	docker logs -f $(NAME)-registry

save: build
	docker save $(NAME):$(VERSION)| gzip > $(NAME)_$(VERSION).img.tar.gz

tag_latest: version
	docker tag $(NAME):$(VERSION) $(NAME):latest

clean: clean-docker-stopped-containers clean-docker-untagged-images
	echo DONE

clean-docker-stopped-containers:
	docker ps -aq --no-trunc | xargs docker rm

clean-docker-untagged-images:
	docker images -q --filter dangling=true | xargs docker rmi
