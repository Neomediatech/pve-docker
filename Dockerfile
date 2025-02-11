FROM debian:bookworm

ENV PVE_VERSION=8.3-1 \
    SERVICE=pve-docker \
    DEBIAN_FRONTEND=noninteractive

LABEL maintainer="docker-dario@neomediatech.it" \ 
      org.label-schema.version=$PVE_VERSION \
      org.label-schema.vcs-type=Git \
      org.label-schema.vcs-url=https://github.com/Neomediatech/${SERVICE} \
      org.label-schema.maintainer=Neomediatech

# set apt config
RUN echo 'APT::Get::Assume-Yes "1";' > /etc/apt/apt.conf.d/00-custom && \
    echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/00-custom && \
    echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/00-custom

# install base pkg
RUN apt-get update && \
    apt-get dist-upgrade && \
    apt-get install wget nano vim curl gnupg ca-certificates rsyslog net-tools iputils-ping tini \
                    sudo systemd systemd-sysv dbus dbus-user-session && \
    rm -rf /var/lib/apt/lists/* /tmp/*

RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d && \
    printf "systemctl start systemd-logind" >> /etc/profile

# add PVE repository
RUN wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg && \
    echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-free.list

RUN apt-get update && \
    apt-get install proxmox-ve postfix open-iscsi chrony && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    sed -i 's/^ConditionVirtualization=!container$/#ConditionVirtualization=!container/' /lib/systemd/system/lxcfs.service

#set (temporary) password for root
RUN echo "root:root"|chpasswd

COPY entrypoint.sh /

RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf && \
    echo '*.* -/proc/1/fd/1' >> /etc/rsyslog.conf && \
    chmod +x /entrypoint.sh

STOPSIGNAL SIGINT
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/sbin/init"]

