FROM busybox:1.36.1-uclibc@sha256:3e516f71d8801b0ce6c3f8f8e4f11093ec04e168177a90f1da4498014ee06b6b as busybox

FROM alpine:3.18.4@sha256:eece025e432126ce23f223450a0326fbebde39cdf496a85d8c016293fc851978 as cloudflared

# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:8879a398dedf0aadaacfbd332b29ff2f84bc39ae6d4e9c0a1109db27ac5ba012 AS xx

# Stage - Build Cloudflared
FROM  golang:1.20-alpine@sha256:174802dbb3172f847f129d75e3cd3f7fe8ef6895a0b1c830f0fc855a4aaf585c as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2023.8.2

RUN apk --update --no-cache add git \
    && \
    # Git clone specify cloudflared version
    git clone --branch ${CLOUDFLARED_VERSION} https://github.com/cloudflare/cloudflared . \
    && \
    # Build cloudflared
    xx-go build -v -mod=vendor -trimpath -o /bin/cloudflared \
    -ldflags="-w -s -X 'main.Version=${CLOUDFLARED_VERSION}' -X 'main.BuildTime=${BUILDTIME}'" \
    ./cmd/cloudflared \
    && \
    # Verify cloudflared
    xx-verify --static /bin/cloudflared

# Stage - Main Image
FROM gcr.io/distroless/base-debian11@sha256:a35b6525fde5572656e24109064dd147fbaedc26e5a7ccd147ff3ed3a4308c21

# Copy Cloudflare binary to image
COPY --from=builder --chown=nonroot /bin/cloudflared /usr/local/bin/cloudflared

# Copy shell, tail into image
COPY --from=busybox /bin/sh /bin/tail /bin/

# Copy entrypoint
COPY --chown=nonroot entrypoint.sh .

# Add nonroot user
USER nonroot

# Tunnel environments
ENV TUNNEL_TOKEN=noToken
ENV POST_QUANTUM=false

ENTRYPOINT [ "/bin/sh", "entrypoint.sh" ]
