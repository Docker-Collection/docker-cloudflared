FROM busybox:1.36.1-uclibc@sha256:babd7b5b0e732133372de4ed790cf08a1c71163e5aca54378c468b291e3bbb8f as busybox

FROM alpine:3.18.0@sha256:02bb6f428431fbc2809c5d1b41eab5a68350194fb508869a33cb1af4444c9b11 as cloudflared

# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:8879a398dedf0aadaacfbd332b29ff2f84bc39ae6d4e9c0a1109db27ac5ba012 AS xx

# Stage - Build Cloudflared
FROM  golang:1.19-alpine@sha256:3723378a4d6d1c80b0db9f0f4d751defd1d29287883b679893da6c34ccfc2fae as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2023.5.1

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
FROM gcr.io/distroless/base-debian11@sha256:73deaaf6a207c1a33850257ba74e0f196bc418636cada9943a03d7abea980d6d

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
