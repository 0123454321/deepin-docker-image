FROM vscwjm/deepin:core-20.8
ENV SHELL=/bin/bash
ENV LANG=en_US.UTF-8
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive \
	apt-get install -y --no-install-recommends \
	apt-transport-https ca-certificates dbus-x11 deepin-keyring gnupg libcups2 libpulse0 libxv1 \
	locales-all mesa-utils mesa-utils-extra nano procps psmisc xdg-utils x11-xkb-utils x11-xserver-utils \
	&& /cleanup
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y equivs \
	&& echo "Section: misc\nPriority: optional\nStandards-Version: 3.9.2\nPackage: deepin-user-experience-daemon\nVersion: 99.0\nProvides: deepin-user-experience-daemon\n" > deepin-user-experience-daemon \
	&& equivs-build deepin-user-experience-daemon \
	&& env DEBIAN_FRONTEND=noninteractive apt-get install -y ./deepin-user-experience-daemon_99.0_all.deb \
	&& apt-get remove -y equivs \
	&& rm deepin-user-experience* \
	&& /cleanup
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive \
	apt-get install -y --no-install-recommends dde-control-center dde-clipboard dde-desktop dde-dock \
	dde-file-manager dde-kwin dde-launcher dde-qt5integration deepin-artwork deepin-default-settings \
	deepin-desktop-base deepin-wallpapers fonts-noto startdde \
	&& /cleanup
RUN apt-get update &&  env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
	dde-calendar deepin-album deepin-calculator deepin-draw deepin-editor deepin-image-viewer deepin-movie \
	deepin-music deepin-screenshot deepin-system-monitor deepin-terminal deepin-voice-note oneko sudo \
	&& /cleanup
ENV XMODIFIERS=@im=fcitx QT4_IM_MODULE=fcitx QT_IM_MODULE=fcitx GTK_IM_MODULE=fcitx
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y citx-sunpinyin \
	&& mkdir -p /etc/xdg/autostart \
	&& echo "[Desktop Entry]\nEncoding=UTF-8\nVersion=0.9.4\nType=Application\nName=fcitx\nComment=\nExec=/usr/bin/fcitx-autostart\n" > /etc/xdg/autostart/fcitx.desktop \
	&& /cleanup
RUN apt-get update && find /var/lib/apt/lists -type f -delete
CMD ["startdde"]]
