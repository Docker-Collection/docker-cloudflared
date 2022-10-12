# Docker Cloudflared

A simple remake version for my use case.

Add `TUNNEL_TOKEN` to environment variable and don't need to use command to connect tunnel.

## Command

```sh
docker run -d --name='Cloudflared' -e 'TUNNEL_TOKEN'='YourToken' 'ghcr.io/docker-collection/cloudflared:latest'
```

## Docker Compose (Recommand)

```yml
version: "3"
services:
  cloudflared:
    image: ghcr.io/docker-collection/cloudflared:latest
    container_name: cloudflared
    environment:
      - TUNNEL_TOKEN=YourToken
      # - POST_QUANTUM=false # Cloudflare Post Quantum, Default: false
    restart: unless-stopped
```
