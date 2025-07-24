IMAGE_NAME = bee-infraverse/pvc-migrate
TAG = latest
FULL_IMAGE = $(IMAGE_NAME):$(TAG)

.PHONY: all build push clean migrate

all: build

print-image:
	@echo "📦 Using image: $(FULL_IMAGE)"

build:
	docker build -t $(FULL_IMAGE) .

push:
	docker push $(FULL_IMAGE)

clean:
	docker rmi $(FULL_IMAGE)

migrate:
	@PVC_SRC=$(word 2, $(MAKECMDGOALS)) && \
	PVC_DST=$(word 3, $(MAKECMDGOALS)) && \
	NS=$(word 4, $(MAKECMDGOALS)) && \
	echo "📦 Migrating PVC $$PVC_SRC to $$PVC_DST in namespace $$NS" && \
	./pvc-migrate.sh $$PVC_SRC $$PVC_DST $$NS
