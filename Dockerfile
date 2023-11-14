FROM debian:bookworm

ENV PVE_VERSION=8.0.4 \
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

RUN apt-get update && \
    apt-get dist-upgrade

# install base pkg
RUN apt-get install wget systemctl nano vim curl gnupg ca-certificates rsyslog net-tools iputils-ping

# add PVE repository
RUN wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg && \
    echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-free.list

RUN apt-get update && \
    apt-get install initramfs-tools && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    echo '#!/bin/bash' > /usr/sbin/update-initramfs && \
    echo 'exit 0' >> /usr/sbin/update-initramfs && \
    chmod +x /usr/sbin/update-initramfs

RUN apt-get update && \
    apt-get install $(apt-cache depends proxmox-ve|awk '{print $2}'|while read x;do apt-cache depends $x 2>/dev/null|grep Depends|awk '{print $2}'|grep ^[[:alnum:]];done|sort|uniq|egrep -v "pve|proxmox|ifenslave|ifupdown2|qemu-server"|xargs) && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# repacked proxmox-ve & pve-manager
RUN apt-get update && \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get install proxmox-ve || echo ok && \
    PVE_PKG="pve-manager" && \
    PVE_VER="$(ls /var/cache/apt/archives/${PVE_PKG}_*.deb|awk -F_ '{print $2}')" && \
    PVE_DEB1="${PVE_PKG}_${PVE_VER}_amd64.deb" && \
    mkdir /tmp/${PVE_PKG} && \
    dpkg -X /var/cache/apt/archives/${PVE_PKG}_${PVE_VER}_amd64.deb /tmp/${PVE_PKG}/ && \
    dpkg -e /var/cache/apt/archives/${PVE_PKG}_${PVE_VER}_amd64.deb /tmp/${PVE_PKG}/DEBIAN && \
    sed -i "s/ifupdown2 (>= 2.0.1-1+pve8) | ifenslave (>= 2.6),//g" /tmp/${PVE_PKG}/DEBIAN/control && \
    sed -i "s/ifupdown2 (>= 3.0) | ifenslave (>= 2.6),//g" /tmp/${PVE_PKG}/DEBIAN/control && \
    dpkg-deb -Zxz  -b /tmp/${PVE_PKG}/ /tmp && \
    PVE_PKG="proxmox-ve" && \
    PVE_VER="$(ls /var/cache/apt/archives/${PVE_PKG}_*.deb|awk -F_ '{print $2}')" && \
    PVE_DEB2="${PVE_PKG}_${PVE_VER}_all.deb" && \
    mkdir /tmp/${PVE_PKG} && \
    dpkg -X /var/cache/apt/archives/${PVE_PKG}_${PVE_VER}_all.deb /tmp/${PVE_PKG}/ && \
    dpkg -e /var/cache/apt/archives/${PVE_PKG}_${PVE_VER}_all.deb /tmp/${PVE_PKG}/DEBIAN && \
    sed -i "s/pve-kernel-helper,//g" /tmp/${PVE_PKG}/DEBIAN/control && \
    sed -i "s/pve-kernel-5.15,//g" /tmp/${PVE_PKG}/DEBIAN/control && \
    sed -i "s/proxmox-default-kernel, //g" /tmp/${PVE_PKG}/DEBIAN/control && \
    dpkg-deb -Zxz  -b /tmp/${PVE_PKG}/ /tmp && \
    dpkg -i /tmp/${PVE_DEB1} && \
    dpkg -i /tmp/${PVE_DEB2} && \
    echo '#!/bin/sh' > /etc/kernel/postrm.d/zz-proxmox-boot && \
    echo 'exit 0' >> /etc/kernel/postrm.d/zz-proxmox-boot && \
    apt-mark hold proxmox-ve && \
    apt-mark hold pve-manager && \
    rm -f /etc/apt/apt.conf.d/*pve* /etc/kernel/postinst.d/* && \
    echo '#!/bin/sh' > /var/lib/dpkg/info/ifupdown2.postinst && \
    echo 'exit 0' >> /var/lib/dpkg/info/ifupdown2.postinst && \
    apt-get -f install && \
    apt-get autoremove --purge && \
    apt-get purge ifupdown2 && \
    apt-get install proxmox-backup-restore-image && \
    rm -rf /var/lib/apt/lists/* /tmp/* && \
    rm -f /etc/apt/sources.list.d/pve-enterprise.list

#set (temporary) password for root
RUN echo "root:root"|chpasswd

COPY entrypoint.sh /

RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf && \
    chmod +x /entrypoint.sh

RUN systemctl disable pvestatd pvefw-logger corosync spiceproxy getty@tty1 postfix ssh.service pve-ha-lrm.service pve-ha-crm.service && \
    systemctl disable pve-firewall.service pvescheduler.service spiceproxy.service || echo ok && \
    systemctl enable rsyslog

#use setup.sh to start proxmox service
STOPSIGNAL SIGINT
ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/lib/systemd/systemd", "log-level=info", "unit=sysinit.target"]

