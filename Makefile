NS ?= mjara
NAME ?= taiga
VERSION ?= latest

default: build

build:
	docker build --pull -t $(NS)/$(NAME):$(VERSION) -f Dockerfile .

publish:
	docker push $(NS)/$(NAME):$(VERSION)

check:
	docker run --rm -i $(NS)/$(NAME):$(VERSION) sh -c "set -x; exit 0"

console:
	docker run --rm -ti --entrypoint sh $(NS)/$(NAME):$(VERSION)

clean:
	docker rmi $(NS)/$(NAME):$(VERSION)
