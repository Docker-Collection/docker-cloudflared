#!/bin/sh

if [ "$TUNNEL_TOKEN" = "noToken" ]; then
  echo "Error: No Token"
  exit 1
else
  cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
fi
