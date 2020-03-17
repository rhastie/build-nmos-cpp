NAME = nmos-cpp
# grab the abrev commit SHA from Dockerfile
VERSION = 0.1S-$(shell sed -n 's/.*NMOS_CPP_VERSION=\(.......\).*/\1/p' Dockerfile)

.PHONY: all version build run save test tag_latest clean-docker-stopped-containers clean-docker-untagged-images

all: build

version:
	@echo Docker image version: $(VERSION)

build: version
	docker build -t $(NAME):$(VERSION) .

run: build
	docker run -it --net=host --rm $(NAME):$(VERSION)

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
