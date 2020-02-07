NAME = nmos-cpp
VERSION = 0.1S-cf54110

.PHONY: all build run save test tag_latest clean-docker-stopped-containers clean-docker-untagged-images

all: build

build:
	docker build -t $(NAME):$(VERSION) .

run: build
	docker run -it --net=host --rm $(NAME):$(VERSION)

save: build
	docker save $(NAME):$(VERSION)| gzip > $(NAME)_$(VERSION).img.tar.gz

test: build
	docker run -it --rm --net=host $(NAME):$(VERSION)

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

clean: clean-docker-stopped-containers clean-docker-untagged-images
	echo DONE

clean-docker-stopped-containers:
	docker ps -aq --no-trunc | xargs docker rm

clean-docker-untagged-images:
	docker images -q --filter dangling=true | xargs docker rmi
