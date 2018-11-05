NAME     = thttpd
REGISTRY = base.docker:5000
VERSION  = 2.29

.PHONY: build clean

all: build

clean-all: clean

build:
	@docker build --rm=true --build-arg VERSION=$(VERSION) -t $(REGISTRY)/$(NAME):$(VERSION) .
	@docker images $(REGISTRY)/$(NAME)

clean:
	@docker rmi $(REGISTRY)/$(NAME):$(VERSION)

default: build
