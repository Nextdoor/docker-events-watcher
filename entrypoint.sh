#!/bin/bash
set +e

while true; do
  docker events --format '{{json .}}' | xargs -d'\n' -I{} -n1 /app/action.sh {}
  sleep 5
done
