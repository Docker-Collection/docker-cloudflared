FROM busybox:1.36.0-uclibc@sha256:133c96e963fb798875f6dd48df3fd6e5d474e28b6f90cebef4f49f5b416200db as busybox

FROM alpine:3.17.2@sha256:69665d02cb32192e52e07644d76bc6f25abeb5410edc1c7a81a10ba3f0efb90a as cloudflared

# Dockerfile cross compilation helper
FROM tonistiigi/xx@sha256:8879a398dedf0aadaacfbd332b29ff2f84bc39ae6d4e9c0a1109db27ac5ba012 AS xx

# Stage - Build Cloudflared
FROM  golang:1.19-alpine@sha256:a00a03c72ecc1a01e4ca7b7cfb62459063912ff45ccb13011f9fb061e25916eb as builder

# Copy xx scripts
COPY --from=xx / /

WORKDIR /src

ARG TARGETPLATFORM
ENV GO111MODULE=on
ENV CGO_ENABLED=0

# renovate: datasource=github-releases depName=cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2023.2.1

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
FROM gcr.io/distroless/base-debian11@sha256:5d40383d8cc15830334f30f4a19e2af16923e02ceeca275f0acc39bdf3a1c577

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
