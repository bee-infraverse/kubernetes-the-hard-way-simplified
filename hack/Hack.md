# Hack

## buildkit

### Start buildkit service

```shell
cd $HOME/kubernetes-the-hard-way-simplified
kubectl create namespace buildkit
kubectl ns buildkit
kubectl apply -f hack/buildkitd/base/buildkitd
kubectl wait --for=condition=available --timeout=30s statefulset/buildkit -n buildkit

# Select first buildkit pod
BUILDKIT_POD=$(kubectl get pods \
  --selector=app=buildkit --field-selector=status.phase=Running \
  -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n buildkit ${BUILDKIT_POD} -c buildkitd -- ps -e
# Show Information of the buildkit daemon
kubectl exec -n buildkit ${BUILDKIT_POD} -c buildkitd -- buildctl debug workers
```

### Build a simple image with buildkit

```shell
mkdir -p ~/curl-images && cd ~/curl-images

# define a simple Dockerfile
cat >Dockerfile <<'EOF'
FROM alpine
RUN apk add curl
ENTRYPOINT curl
ARG VERSION
LABEL \
  org.opencontainers.image.version=$VERSION \
  org.opencontainers.image.licenses="Apache-2.0" \
  org.opencontainers.image.authors="Peter Rossbach"
EOF

# Build the image
export BUILD_VERSION=v1.0.0
export BUILDKIT_HOST=tcp://node-0.local:31234
export REGISTRY_HOST=registry.iximiuz.com
  
buildctl build --frontend dockerfile.v0 \
  --opt build-arg:VERSION=$BUILD_VERSION \
  --opt --platform=linux/amd64 \
  --local context=. \
  --local dockerfile=. \
  --output type=image,name=$REGISTRY_HOST/curl-image:$BUILD_VERSION,push=true
crane manifest $REGISTRY_HOST/curl-image:$BUILD_VERSION

# check
kubectl run --rm -i --tty \
  --image=registry.iximiuz.com/curl-image:$BUILD_VERSION \
  --restart=Never \
  curl-image -- curl -LI https://iximiuz.com
```


Todo:

Detected renovate changes!

```shell
docker run --privileged --rm tonistiigi/binfmt:qemu-v9.2.2 --uninstall qemu-*
docker run --privileged --rm tonistiigi/binfmt:qemu-v9.2.2 --install all
```

