#!/bin/sh

pid=0

term_handler() {
  if [ "$pid" -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  exit 143;
}

trap 'kill ${!}; term_handler' TERM

if [ "$TUNNEL_TOKEN" = "noToken" ]; then
  echo "Error: No Token"
  exit 1
elif [ "$POST_QUANTUM" = true ]; then
  cloudflared tunnel --no-autoupdate run --post-quantum --token "$TUNNEL_TOKEN" &
  pid="$!"
else
  cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN" &
  pid="$!"
fi

while :; do
    tail -f /dev/null & wait ${!}
done
