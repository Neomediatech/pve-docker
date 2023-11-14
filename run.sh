#!/bin/bash
# shell vars set here will be overridden by same shell vars set in $BASE_PATH/.shell-vars file
BASE_PATH="/srv/pve"
IMAGE="neomediatech/pve:latest"
#IMAGE="pve"
NAME="pve"
VOLUMES="" # volumes set here will be added to volumes found in $BASE_PATH/.volumes file (if it exists)
PORTS="-p 8006:8006"
OPTIONS=""
OPTIONS="$OPTIONS --privileged --device /dev/fuse --device=/dev/kvm --add-host $NAME:127.0.0.1"
OPTIONS="$OPTIONS --tmpfs /tmp --tmpfs /run --tmpfs /run/lock --cgroupns private"
ENVS="" # vars set here will override same vars in $BASE_PATH/.env file
ENTRYPOINT=""
#ENTRYPOINT="--entrypoint /bin/bash"
INTERACTIVE="no"

if [ -f $BASE_PATH/.shell-vars ]; then
    source $BASE_PATH/.shell-vars
fi

if [ -f $BASE_PATH/.volumes ]; then
    for VOLUME in $(cat $BASE_PATH/.volumes); do
        VOLUMES="$VOLUMES -v $(eval "echo $VOLUME")"
    done
fi

if [ -f $BASE_PATH/.env ]; then
    ENVS="--env-file $BASE_PATH/.env $ENVS"
fi

if [ "$INTERACTIVE" == "yes" ]; then
    RUN_OPTIONS="-it"
else
    RUN_OPTIONS="-d"
fi

echo "Stopping existing Proxmox VE instances..."
docker stop $NAME 2>/dev/null
echo "Deleting old Proxmox VE instances..."
docker rm $NAME 2>/dev/null
echo "Pulling new version of Proxmox VE Docker image..."
docker pull $IMAGE 2>/dev/null
echo "Starting Proxmox VE..."
docker run $RUN_OPTIONS $PORTS --name $NAME --hostname $NAME $OPTIONS $VOLUMES $ENVS $ENTRYPOINT $IMAGE

