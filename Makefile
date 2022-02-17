NAME = nmos-cpp
# grab the abrev commit SHA from Dockerfile
VERSION = 1.2A-$(shell sed -n 's/.*NMOS_CPP_VERSION=\(.......\).*/\1/p' Dockerfile)
# Get number of processors available and add 1
NPROC = $(shell echo $(shell nproc)+1 | bc)

.PHONY: all version build run save test tag_latest clean-docker-stopped-containers clean-docker-untagged-images

all: build

version:
	@echo Docker image version: $(VERSION)

build: version
	docker build -t $(NAME):$(VERSION) --build-arg makemt=$(NPROC) .

buildnode: version
	docker build -t $(NAME)-node:$(VERSION) --build-arg makemt=$(NPROC) --build-arg runnode=TRUE .

buildx: version
	docker buildx build --platform linux/amd64,linux/arm64 -t rhastie/$(NAME):$(VERSION) --build-arg makemt=$(NPROC) --push .
# Example below on how to push multi-arch manifest to NVIDIA GPU Cloud (NGC)
#	docker buildx build --platform linux/amd64,linux/arm64 -t nvcr.io/nvidian/$(NAME):$(VERSION) --build-arg makemt=$(NPROC) --push .
# Example below on how to push multi-arch manifest to Git Hub Packages
#       docker buildx build --platform linux/amd64,linux/arm64 -t docker.pkg.github.com/rhastie/build-nmos-cpp/$(NAME):$(VERSION) --build-arg makemt=$(NPROC) --push .
# Example below on how to push multi-arch manifest to Amazon ECR
#	docker buildx build --platform linux/amd64,linux/arm64 -t 299832127819.dkr.ecr.us-east-1.amazonaws.com/mellanox/$(NAME):$(VERSION) --build-arg makemt=$(NPROC) --push .

run: build
	docker run -d -it --net=host --name $(NAME)-registry --rm $(NAME):$(VERSION)

runnode: buildnode
	docker run -d -it --net=host --name $(NAME)-node --rm $(NAME)-node:$(VERSION)

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
