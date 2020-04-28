#!/bin/bash
set -e

############################################################################
#
# Modifies a starting container's routing table to include a route to the 
# host's VPC with the specified RTO value.
#
############################################################################
RTO_MIN=${RTO_MIN-200}
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

# Get default interface info
CONTAINER_DEFAULT_IF=$(awk '$2 == 00000000 { print $1 }' /host/proc/$CONTAINER_PID/net/route)
logger "CONTAINER_DEFAULT_IF=$CONTAINER_DEFAULT_IF"
if [ -z "$CONTAINER_DEFAULT_IF" ] ; then
  logger "bailing because CONTAINER_DEFAULT_IF was empty"
  cleanup
  exit
fi

CONTAINER_DEFAULT_IP=$(ip netns exec $CONTAINER_PID ip addr show dev $CONTAINER_DEFAULT_IF | grep "inet " | cut -d ' ' -f 6  | cut -f 1 -d '/')
logger "CONTAINER_DEFAULT_IP=$CONTAINER_DEFAULT_IP"
if [ -z "$CONTAINER_DEFAULT_IP" ] ; then
  logger "bailing because CONTAINER_DEFAULT_IP was empty"
  cleanup
  exit
fi

CONTAINER_GATEWAY_IP=$(ip netns exec $CONTAINER_PID ip route show default | awk '/default/ {print $3}')
logger "CONTAINER_GATEWAY_IP=$CONTAINER_GATEWAY_IP"
if [ -z "$CONTAINER_GATEWAY_IP" ] ; then
  logger "bailing because CONTAINER_GATEWAY_IP was empty"
  cleanup
  exit
fi

CONTAINER_DEFAULT_MAC=$(ip netns exec $CONTAINER_PID ifconfig $CONTAINER_DEFAULT_IF | grep HWaddr | awk '{print $5}')
logger "CONTAINER_DEFAULT_MAC=$CONTAINER_DEFAULT_MAC"
if [ -z "$CONTAINER_DEFAULT_MAC" ] ; then
  logger "bailing because CONTAINER_DEFAULT_MAC was empty"
  cleanup
  exit
fi

# If mac starts with 02:42:ac then we know this is a docker assigned mac (not using AWS ENI).
if  [[ $CONTAINER_DEFAULT_MAC == "02:42:ac"* ]] ; then
  logger "found docker mac checking ec2 metadata"
  REAL_MAC=$(curl --fail -s http://169.254.169.254/latest/meta-data/mac)
else
  REAL_MAC=$CONTAINER_DEFAULT_MAC
fi

logger "picked mac $REAL_MAC"
VPC_CIDR=$(curl --fail -s http://169.254.169.254/latest/meta-data/network/interfaces/macs/$REAL_MAC/vpc-ipv4-cidr-block)

logger "setting RTO on $VPC_CIDR via $CONTAINER_GATEWAY_IP dev $CONTAINER_DEFAULT_IF to $RTO_MIN"
ip netns exec $CONTAINER_PID ip route add $VPC_CIDR via $CONTAINER_GATEWAY_IP dev $CONTAINER_DEFAULT_IF rto_min $RTO_MIN
cleanup
