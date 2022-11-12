FROM busybox:1.35.0-uclibc@sha256:36d11d54b0a8b4956ab65bb593b7e6e5f11e762f1e6d99ca755b43499e35d6c9 as busybox

FROM alpine:3.16.3@sha256:b95359c2505145f16c6aa384f9cc74eeff78eb36d308ca4fd902eeeb0a0b161b as cloudflared

# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:9dde7edeb9e4a957ce78be9f8c0fbabe0129bf5126933cd3574888f443731cda AS xx

# Stage - Build Cloudflared
FROM  golang:1.19-alpine@sha256:dc4f4756a4fb91b6f496a958e11e00c0621130c8dfbb31ac0737b0229ad6ad9c as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2022.10.3

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
FROM gcr.io/distroless/base-debian11@sha256:a215fd3bc92252f4d0e889cff3f3a820549d3e307c4ce98590cda3556d95e6d6

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
