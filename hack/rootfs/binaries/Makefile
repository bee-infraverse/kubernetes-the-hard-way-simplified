# --- Variablen ---
IMAGE_NAME := kubernetes-the-hard-way-simplified-binaries
IMAGE_TAG  := v0.1.0

TARGET_OS   ?= linux
TARGET_ARCH ?= amd64
K8S_VERSION ?= v1.34.2
HELM_VERSION ?= v3.19.1
K9S_VERSION ?= v0.50.16
CRICTL_VERSION ?= v1.34.0
RUNC_VERSION ?= v1.3.4
CNI_PLUGINS =? v1.7.1
CONTAINERD_VERSION =? 2.1.5
ETCD_VERSION =? v3.6.5
NERDCTL_VERSION =? 2.1.5

VCS_REF     ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo unknown)
BUILD_DATE  ?= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

DOCKERFILE := Dockerfile

# --- Standard Build ---
.PHONY: build
build:
	docker build \
	  --file $(DOCKERFILE) \
	  --build-arg KTHW_VERSION=$(IMAGE_TAG) \
	  --build-arg K8S_VERSION=$(K8S_VERSION) \
	  --build-arg HELM_VERSION=$(HELM_VERSION) \
	  --build-arg K9S_VERSION=$(K9S_VERSION) \
      --build-arg CRICTL_VERSION=${CRICTL_VERSION} \
      --build-arg RUNC_VERSION=${RUNC_VERSION} \
      --build-arg CNI_PLUGINS=${CNI_PLUGINS} \
      --build-arg CONTAINERD_VERSION=${CONTAINERD_VERSION} \
      --build-arg ETCD_VERSION=${ETCD_VERSION} \
      --build-arg NERDCTL_VERSION=${NERDCTL_VERSION} \
	  --build-arg VCS_REF=$(VCS_REF) \
	  --build-arg BUILD_DATE=$(BUILD_DATE) \
	  --platform linux/amd64 \
	  -t $(IMAGE_NAME):$(IMAGE_TAG) \
	  .

# --- Build + push ---
.PHONY: push
push: build
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

# --- Clean (optional) ---
.PHONY: clean
clean:
	docker rmi -f $(IMAGE_NAME):$(IMAGE_TAG) || true

# --- Debug: show variables ---
.PHONY: info
info:
	@echo "IMAGE_NAME: $(IMAGE_NAME)"
	@echo "IMAGE_TAG: $(IMAGE_TAG)"
	@echo "TARGET_OS: $(TARGET_OS)"
	@echo "TARGET_ARCH: $(TARGET_ARCH)"
	@echo "K8S_VERSION: $(K8S_VERSION)"
	@echo "HELM_VERSION: $(HELM_VERSION)"
	@echo "K9S_VERSION: $(K9S_VERSION)"
	@echo "CRICTL_VERSION: $(CRICTL_VERSION)"
	@echo "RUNC_VERSION: $(RUNC_VERSION)"
	@echo "CNI_PLUGINS: $(CNI_PLUGINS)"
	@echo "CONTAINERD_VERSION: $(CONTAINERD_VERSION)"
	@echo "ETCD_VERSION: $(ETCD_VERSION)"
	@echo "NERDCTL_VERSION: $(NERDCTL_VERSION)"
	@echo "VCS_REF: $(VCS_REF)"
	@echo "BUILD_DATE: $(BUILD_DATE)"