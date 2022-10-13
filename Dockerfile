FROM busybox:1.35.0-uclibc@sha256:af3f6ba4bcf04a5593e9bb84791d1ffb5bc870e750e2423bdd7ab3b3805c4b15 as busybox

FROM alpine:3.16.2@sha256:1304f174557314a7ed9eddb4eab12fed12cb0cd9809e4c28f29af86979a3c870 as cloudflared

# renovate: datasource=github-releases depName=cloudflare/cloudflared
ARG CLOUDFLARED_VERSION=2022.10.0

RUN ARCH=$([ "$(uname -m)" = "x86_64" ] && echo "amd64" || echo "arm64") \
    && \
    apk add wget curl jq coreutils \
    && \
    wget -O /usr/local/bin/cloudflared https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${ARCH} \
    && \
    CHECKSUM=$(curl -H "Accept: application/vnd.github+json" https://api.github.com/repos/cloudflare/cloudflared/releases/tags/${CLOUDFLARED_VERSION} | jq -r .body | grep cloudflared-linux-${ARCH}: | cut -d ":" -f 2) \
    && \
    echo "${CHECKSUM} /usr/local/bin/cloudflared" | sha256sum --check \ 
    && \
    chmod +x /usr/local/bin/cloudflared

# Main Image
FROM gcr.io/distroless/base-debian11@sha256:cefeffd60bd9127a3bb53dc83289cf1718a81710465d7377d9d25e8137b58c83

# Copy Cloudflare binary to image
COPY --from=cloudflared --chown=nonroot /usr/local/bin/cloudflared /usr/local/bin/cloudflared

# Copy shell to image
COPY --from=busybox /bin/sh /bin/sh

# Copy tail to iamge
COPY --from=busybox /bin/tail /bin/tail

# Copy entrypoint
COPY --chown=nonroot entrypoint.sh .

# Add nonroot user
USER nonroot

# Tunnel environments
ENV TUNNEL_TOKEN=noToken
ENV POST_QUANTUM=false

ENTRYPOINT [ "/bin/sh", "entrypoint.sh" ]
