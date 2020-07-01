KUTTL_VERSION=0.5.0
KIND_VERSION=0.8.1
KUBERNETES_VERSION ?= 1.17.5
KUBECONFIG=kubeconfig

OS=$(shell uname -s | tr '[:upper:]' '[:lower:]')
MACHINE=$(shell uname -m)
KIND_MACHINE=$(shell uname -m)
ifeq "$(KIND_MACHINE)" "x86_64"
  KIND_MACHINE=amd64
endif

export PATH := $(shell pwd)/bin/:$(PATH)

ARTIFACTS=dist

bin/kind_$(KIND_VERSION):
	mkdir -p bin/
	curl -Lo bin/kind_$(KIND_VERSION) https://github.com/kubernetes-sigs/kind/releases/download/v$(KIND_VERSION)/kind-$(OS)-$(KIND_MACHINE)
	chmod +x bin/kind_$(KIND_VERSION)

bin/kind: bin/kind_$(KIND_VERSION)
	ln -sf ./kind_$(KIND_VERSION) bin/kind

bin/kubectl-kuttl_$(KUTTL_VERSION):
	mkdir -p bin/
	curl -Lo bin/kubectl-kuttl_$(KUTTL_VERSION) https://github.com/kudobuilder/kuttl/releases/download/v$(KUTTL_VERSION)/kubectl-kuttl_$(KUTTL_VERSION)_$(OS)_$(MACHINE)
	chmod +x bin/kubectl-kuttl_$(KUTTL_VERSION)

bin/kubectl-kuttl: bin/kubectl-kuttl_$(KUTTL_VERSION)
	ln -sf ./kubectl-kuttl_$(KUTTL_VERSION) bin/kubectl-kuttl

.PHONY: install-bin
install-bin: bin/kind bin/kubectl-kuttl

.PHONY: create-kind-cluster
create-kind-cluster: $(KUBECONFIG)

$(KUBECONFIG): install-bin
	bin/kind create cluster --wait 10s --image=kindest/node:v$(KUBERNETES_VERSION)

.PHONY: kind-test
kind-test: create-kind-cluster
	./run-tests.sh
	bin/kind delete cluster
	rm $(KUBECONFIG)

.PHONY: clean
clean:
	bin/kind delete cluster
	rm -f $(KUBECONFIG)
	rm -rf dist
	# delete the checked out repository
	rm -rf kubeaddons-enterprise
