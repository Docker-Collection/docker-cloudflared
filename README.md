# Docker Cloudflared

A simple remake version for my use case.

Add `TUNNEL_TOKEN` to environment variable and don't need to use command to connect tunnel.

## Environment variables

- ``TUNNEL_TOKEN``: Tunnel running key created on [Access - Tunnels](https://dash.teams.cloudflare.com/) (Default: noToken)
- ``POST_QUANTUM``: Experimental post-quantum tunnel (Default: false)

## Usage

### **Command**

```sh
docker run -d --name='Cloudflared' \
  -e 'TUNNEL_TOKEN'='YourToken' \
  -e 'POST_QUANTUM'='false' \
  'ghcr.io/docker-collection/cloudflared:latest'
```

### **Docker Compose** (Recommand)

```yml
version: "3"
services:
  cloudflared:
    image: ghcr.io/docker-collection/cloudflared:latest
    restart: unless-stopped
    container_name: cloudflared
    environment:
      - TUNNEL_TOKEN=YourToken
      - POST_QUANTUM=false
```
