FROM busybox:1.35.0-uclibc@sha256:0ea1080c8e2ff1a236443a203b92deee68cf10fb06b640e038f5c51342c12c65 as busybox

FROM alpine:3.17.0@sha256:8914eb54f968791faf6a8638949e480fef81e697984fba772b3976835194c6d4 as cloudflared

# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:9dde7edeb9e4a957ce78be9f8c0fbabe0129bf5126933cd3574888f443731cda AS xx

# Stage - Build Cloudflared
FROM  golang:1.19-alpine@sha256:d171aa333fb386089206252503bc6ab545072670e0286e3d1bbc644362825c6e as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2022.11.1

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
