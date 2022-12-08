GO ?= go
BUF_VERSION=v1.8.0
GRPCURL_VERSION=v1.8.7
PROTOC_GEN_GO=v1.28
PROTOC_GEN_GO_GRPC=v1.2
PROTO_GO_REPO ?= https://github.com/rongpengju/k4s-api-gen.git
PROTO_GO_TARGET_REPO ?= deploy/proto-go

MAJOR=1
MINOR=1
MINOR_BEGIN_AT="2022-10-01T00:00:00+08:00"
PATCH=$(shell git rev-list --count --since="${MINOR_BEGIN_AT}" HEAD)
TAG=$(MAJOR).$(MINOR).$(PATCH)

build: clean lint generator

.PHONY: install
install:
	$(GO) get -u github.com/golang/protobuf
	$(GO) install github.com/bufbuild/buf/cmd/buf@$(BUF_VERSION)
	$(GO) install github.com/fullstorydev/grpcurl/cmd/grpcurl@$(GRPCURL_VERSION)
	$(GO) install google.golang.org/protobuf/cmd/protoc-gen-go@$(PROTOC_GEN_GO)
	$(GO) install google.golang.org/grpc/cmd/protoc-gen-go-grpc@$(PROTOC_GEN_GO_GRPC)

.PHONY: lint
lint:
	buf lint
	buf format --diff --exit-code

.PHONY: format
format:
	buf format --diff -w

.PHONY: generator
generator:
	buf generate

push-to-go-repo:
	test -d deploy || mkdir -p deploy
	test -d $(PROTO_GO_TARGET_REPO) || git clone $(PROTO_GO_REPO) $(PROTO_GO_TARGET_REPO)
	cp -r gen/* $(PROTO_GO_TARGET_REPO)/
	cd $(PROTO_GO_TARGET_REPO) && $(GO) mod init github.com/rongpengju/k4s-api-gen || true
	cd $(PROTO_GO_TARGET_REPO) && $(GO) mod tidy
	git config --global user.email "gophercoding@gmail.com"
	git config --global user.name "rongpengju"
	(cd $(PROTO_GO_TARGET_REPO) && git add --all && git commit -m "[auto-commit] Generate codes" && git tag $(TAG) && && git push origin $(TAG) && git push -f -u origin master) || echo "not pushed"

clean:
	rm -rf gen deploy
