# Docker Events Watcher

This is a docker container which listens to the host's docker events stream and takes actions by executing shell scripts. This is accomplished by exposing this container to the host's `/var/run/docker.sock` and `/proc`. Take special care as this container is run with privileged mode.

## Running

```
docker run \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /proc:/host/proc \
--privileged \
--network host \
docker-events-watcher:latest
```