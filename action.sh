#!/bin/bash

DOCKER_EVENT=$@

# Echo event for logging purposes.
echo $DOCKER_EVENT

EVENT_ACTION=$(echo $DOCKER_EVENT |  jq ".Action" --raw-output)
EVENT_TYPE=$(echo $DOCKER_EVENT | jq ".Type" --raw-output)

# Skip exec events
if  [[ $EVENT_ACTION == exec_* ]] ; then
  exit
fi

# Find actions to do for a docker event type/action combo
ACTIONS_DIR="/app/actions/$EVENT_TYPE/$EVENT_ACTION"
if [ ! -d $ACTIONS_DIR ]; then
  exit
fi

ACTIONS=$(find $ACTIONS_DIR -type f -printf '%P\n' | sort)

# Do each action
for action in $ACTIONS; do
  exec $ACTIONS_DIR/$action $DOCKER_EVENT
done
