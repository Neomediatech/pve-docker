#!/bin/bash
set -eo pipefail
shopt -s nullglob

# logging functions
pve_log() {
	local type="$1"; shift
	printf '%s [%s] [Entrypoint]: %s\n' "$(date --rfc-3339=seconds)" "$type" "$*"
}
pve_note() {
	pve_log Note "$@"
}
pve_warn() {
	pve_log Warn "$@" >&2
}
pve_error() {
	pve_log ERROR "$@" >&2
	exit 1
}

# Verify that the minimally required password settings are set for new databases.
docker_verify_minimum_env() {
	if [ -z "$ADMIN_PASSWORD" ]; then
		pve_error $'Password option is not specified\n\tYou need to specify an ADMIN_PASSWORD'
	fi
}

docker_setup_pve() {
    #Set pve user
    echo "root:$ADMIN_PASSWORD"|chpasswd
}

RELAY_HOST=${RELAY_HOST:-ext.home.local}
sed -i "s/RELAY_HOST/$RELAY_HOST/" /etc/postfix/main.cf
PVE_ENTERPRISE=${PVE_ENTERPRISE:-no}
if [ "$PVE_ENTERPRISE" != "yes" ]; then
    rm -f /etc/apt/sources.list.d/pve-enterprise.list
fi

docker_verify_minimum_env

# Start api first in background
#echo -n "Starting Proxmox VE API..."
#/usr/lib/x86_64-linux-gnu/proxmox-backup/proxmox-backup-api &
#while true; do
#    if [ ! -f /run/proxmox-backup/api.pid ]; then
#        echo -n "..."
#        sleep 3
#    else
#        break
#    fi
#done
#echo "OK"

docker_setup_pve

if [ ! -d /var/log/pveproxy ]; then
    mkdir -p /var/log/pveproxy
fi
chmod 777 /var/log/pveproxy
touch /var/log/pveproxy/access.log
chmod 666 /var/log/pveproxy/access.log

if [ -n "$ENABLE_PVE_FIREWALL" -a "$ENABLE_PVE_FIREWALL" == "no" ]; then
    systemctl mask pve-firewall.service
fi

echo "Running PVE..."
exec "$@"
#exec gosu backup /usr/lib/x86_64-linux-gnu/proxmox-backup/proxmox-backup-proxy "$@"

