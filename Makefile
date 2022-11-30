GO ?= go
BUF_VERSION=v1.8.0
PROTO_GO_REPO ?= https://github.com/rongpengju/k4s-api-gen.git
PROTO_GO_TARGET_REPO ?= deploy/proto-go
BIN ?= /usr/local/bin
BINARY_NAME ?= buf

build: clean lint generator

.PHONY: install
install:
	  curl -sSL "https://github.com/bufbuild/buf/releases/download/${BUF_VERSION}/${BINARY_NAME}" -o "${BIN}/${BINARY_NAME}" && chmod +x "${BIN}/${BINARY_NAME}"

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
	(cd $(PROTO_GO_TARGET_REPO) && git add --all && git commit -m "[auto-commit] Generate codes" && git push -f -u origin master) || echo "not pushed"

clean:
	rm -rf gen deploy
