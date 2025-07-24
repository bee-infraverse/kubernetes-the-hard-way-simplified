FROM alpine:3.21

LABEL maintainer="Kubernetes Authors" \
      description="This image is used to migrate Persistent Volume Claims (PVCs) in Kubernetes."

RUN apk add --no-cache rsync
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]