FROM busybox:1.36.0-uclibc@sha256:133c96e963fb798875f6dd48df3fd6e5d474e28b6f90cebef4f49f5b416200db as busybox

FROM alpine:3.17.1@sha256:f271e74b17ced29b915d351685fd4644785c6d1559dd1f2d4189a5e851ef753a as cloudflared

# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:66ffe58bd25bf822301324183a2a2743a4ed5db840253cc96b36694ef9e269d9 AS xx

# Stage - Build Cloudflared
FROM  golang:1.19-alpine@sha256:2381c1e5f8350a901597d633b2e517775eeac7a6682be39225a93b22cfd0f8bb as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2023.1.0

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
FROM gcr.io/distroless/base-debian11@sha256:0b9ec3cfe2fef19e5514290c666e0bb3fca2baf61df05550b4712ddaea1d3693

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
