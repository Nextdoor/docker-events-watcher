#!/bin/bash
set -e

############################################################################
#
# Modifies a starting container's sysctl tuning values.
#
# NOTE: If you change a value in here and also need it set on the host, please
#       do so in the puppet-base repo. If you add a sysctl value on the host and
#       need it on your docker container, please add it here.
#
#       This script should only be run on ubuntu 18 (or other tested OS.)
#
############################################################################
ME=`basename "$0"`

# Catch the case that a container dies quickly.
sleep 1

logger() {
  echo "$ME [$CONTAINER_ID]: $1"
}

cleanup () {
  if [ -h /var/run/netns/$CONTAINER_PID ]; then
    rm /var/run/netns/$CONTAINER_PID
  fi
}

DOCKER_EVENT=$@
CONTAINER_ID=$(echo $DOCKER_EVENT | jq ".Actor.ID" --raw-output)
CONTAINER=$(docker inspect --format '{{json .}}' $CONTAINER_ID)
CONTAINER_PID=$(echo $CONTAINER | jq ".State.Pid" --raw-output)

logger "running"
if [ "$CONTAINER_PID" = "0" ] ; then
  logger "bailing because container not running"
  exit
fi

# Mount container's (pid's) network namesapce and update routing table 
mkdir -p /var/run/netns
ln -s /host/proc/$CONTAINER_PID/ns/net /var/run/netns/$CONTAINER_PID

#
# NOTE: This will set sysctl values for all docker containers. If you need to change a sysctl
#       setting on the host, please add it to the puppet-base default.yaml hiera hierarchy.
#       Additionally, if you made a change in the puppet-base default.yaml hiera hierarchy and need
#       it applied to your docker containers, you will need to add it to this list.
#
# Some of the values below are commented out as they are not writable in a docker container.
#
logger "setting sysctl values"
# dont bail if one of these fails
set +e
set -x
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.ip_local_port_range='32769 61000'
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_timestamps=1
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_slow_start_after_idle=0
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_syncookies=1
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_window_scaling=1
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_max_tw_buckets=1048576
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.icmp_echo_ignore_broadcasts=1
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.icmp_ignore_bogus_error_responses=1
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_max_syn_backlog=10240
#ip netns exec $CONTAINER_PID sysctl -w net.core.netdev_max_backlog=4096
#ip netns exec $CONTAINER_PID sysctl -w net.core.somaxconn=4096
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_fin_timeout=30
ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_keepalive_time=300
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_wmem='4096 16384 16777216'
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_rmem='4096 16384 16777216'
#ip netns exec $CONTAINER_PID sysctl -w net.core.rmem_max=16777216
#ip netns exec $CONTAINER_PID sysctl -w net.core.wmem_max=16777216
#ip netns exec $CONTAINER_PID sysctl -w vm.swappiness=1
#ip netns exec $CONTAINER_PID sysctl -w kernel.core_uses_pid=1
#ip netns exec $CONTAINER_PID sysctl -w kernel.panic=1
#ip netns exec $CONTAINER_PID sysctl -w kernel.softlockup_panic=1
#ip netns exec $CONTAINER_PID sysctl -w vm.overcommit_memory=0
#ip netns exec $CONTAINER_PID sysctl -w vm.overcommit_ratio=50
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.tcp_tw_reuse=1
#ip netns exec $CONTAINER_PID sysctl -w net.ipv4.neigh.default.gc_thresh1=0
set +x
set -e

logger "running cleanup"
cleanup
