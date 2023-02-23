# x11docker/deepin
# 
# Run deepin desktop in a Docker container. 
# Use x11docker to run image: 
#   https://github.com/mviereck/x11docker 
#
# Run deepin desktop with:
#   x11docker --desktop --init=systemd -- --cap-add=IPC_LOCK -- x11docker/deepin
#
# Run single application:
#   x11docker x11docker/deepin deepin-terminal
#
# Options:
# Persistent home folder stored on host with   --home
# Share host file or folder with option        --share PATH
# Hardware acceleration with option            --gpu
# Clipboard sharing with option                --clipboard
# Language locale setting with option          --lang [=$LANG]
# Sound support with option                    --pulseaudio
# Printer support with option                  --printer
# Webcam support with option                   --webcam
#
# See x11docker --help for further options.

#### stage 0: debian, debootstrap ####
FROM debian:buster

# Choose a deepin mirror close to your location.
# Many further mirrors are listed at: https://www.deepin.org/en/mirrors/packages/
#ENV DEEPIN_MIRROR=http://packages.deepin.com/deepin/
#ENV DEEPIN_MIRROR=http://mirrors.ustc.edu.cn/deepin/
ENV DEEPIN_MIRROR=http://mirrors.kernel.org/deepin/
#ENV DEEPIN_MIRROR=http://ftp.fau.de/deepin/

ENV DEEPIN_RELEASE=apricot

# prepare sources and keys
RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        multistrap \
        gnupg && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 425956BB3E31DF51 && \
    mkdir -p /rootfs/etc/apt && \
    cp /etc/apt/trusted.gpg /rootfs/etc/apt/trusted.gpg && \
    echo "deb     $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" > /rootfs/etc/apt/sources.list && \
    echo "deb-src $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" >> /rootfs/etc/apt/sources.list

# cleanup script for use after apt-get
RUN echo '#!/bin/sh\n\
env DEBIAN_FRONTEND=noninteractive apt-get autoremove -y\n\
apt-get clean\n\
find /var/lib/apt/lists -type f -delete\n\
find /var/cache -type f -delete\n\
find /var/log -type f -delete\n\
exit 0\n\
' > /rootfs/cleanup && chmod +x /rootfs/cleanup

# multistrap recipe for deepin
RUN echo "[General]\n\
arch=amd64\n\
directory=/rootfs/\n\
cleanup=true\n\
noauth=false\n\
unpack=true\n\
explicitsuite=false\n\
multiarch=\n\
aptsources=Debian\n\
bootstrap=Deepin\n\
[Deepin]\n\
packages=apt\n\
source=$DEEPIN_MIRROR\n\
keyring=debian-archive-keyring\n\
suite=$DEEPIN_RELEASE\n\
" >/deepin.multistrap

RUN multistrap -f /deepin.multistrap

RUN mkdir -p /rootfs/etc/apt && \
    cp /etc/apt/trusted.gpg /rootfs/etc/apt/trusted.gpg && \
    echo "deb     $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" > /rootfs/etc/apt/sources.list && \
    echo "deb-src $DEEPIN_MIRROR $DEEPIN_RELEASE main non-free contrib" >> /rootfs/etc/apt/sources.list

RUN chroot ./rootfs /usr/bin/apt-get update && \
    chroot ./rootfs env DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    chroot ./rootfs /cleanup 

#### stage 1: deepin ####
FROM scratch
COPY --from=0 /rootfs /

ENV SHELL=/bin/bash
ENV LANG=en_US.UTF-8
ENV XMODIFIERS=@im=fcitx QT4_IM_MODULE=fcitx QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx
# basics
RUN apt-get update && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        dbus-x11 \
        deepin-keyring \
        gnupg \
        libcups2 \
        libpulse0 \
        libxv1 \
        locales-all \
        mesa-utils \
        mesa-utils-extra \
        procps \
        psmisc \
        xdg-utils \
        x11-xkb-utils \
        x11-xserver-utils && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        udisks2 || rm -v /var/lib/dpkg/info/udisks2.postinst && \
    dpkg --configure udisks2 && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        dde-control-center \
        dde-clipboard \
        dde-desktop \
        dde-dock \
        dde-file-manager \
        dde-kwin \
        dde-launcher \
        dde-qt5integration \
        deepin-artwork \
        deepin-default-settings \
        deepin-desktop-base \
        deepin-wallpapers \
        fonts-noto \
        startdde && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        dde-calendar \
        deepin-album \
        deepin-calculator \
        deepin-draw \
        deepin-editor \
        deepin-image-viewer \
        deepin-movie \
        deepin-music \
        deepin-screenshot \
        deepin-system-monitor \
        deepin-terminal \
        deepin-voice-note \
        oneko \
        sudo && \
    env DEBIAN_FRONTEND=noninteractive apt-get install -y \
        fcitx-sunpinyin && \
    mkdir -p /etc/xdg/autostart && \
    echo "[Desktop Entry]\n\
Encoding=UTF-8\n\
Version=0.9.4\n\
Type=Application\n\
Name=fcitx\n\
Comment=\n\
Exec=/usr/bin/fcitx-autostart\n\
" > /etc/xdg/autostart/fcitx.desktop \
    && cd /bin && ln -s busybox wget \
    && wget https://github.com/kasmtech/KasmVNC/releases/download/v1.0.1/kasmvncserver_buster_1.0.1_amd64.deb \
    && apt-get install ./kasmvncserver_buster_1.0.1_amd64.deb -y \
    && rm kasmvncserver_buster_1.0.1_amd64.deb \
    && echo "deb https://community-packages.deepin.com/deepin/ apricot main contrib non-free" >/etc/apt/sources.list \
    && echo "deb https://com-store-packages.uniontech.com/appstore deepin appstore" >/etc/apt/sources.list.d/appstore.list \
    && echo "deb https://pro-driver-packages.uniontech.com eagle non-free" >/etc/apt/sources.list.d/devicemanager.list \
    && echo "deb https://community-packages.deepin.com/driver/ driver non-free" >/etc/apt/sources.list.d/driver.list \
    && echo "deb https://community-packages.deepin.com/printer eagle non-free" >/etc/apt/sources.list.d/printer.list \
    && apt-get update && dpkg --add-architecture i386 && apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends com.qq.weixin.deepin \
    && /cleanup
CMD ["startdde"]