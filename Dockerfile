FROM scratch
#加载20.3基础系统包
ADD docker-image_deepin-20.03-core_upx.tar.gz /
#加载清理脚本
COPY cleanup /
#设置语言
ENV LANG=en_US.UTF-8
#更新系统将系统从20.3升级到20.8
RUN apt-get update && apt-get dist-upgrade -y \
	&& apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
		#解决apt使用https源报证书错误的问题
		apt-transport-https  ca-certificates \
		dbus-x11 deepin-keyring gnupg libcups2 libpulse0 libxv1 \
		#locales-all 包含有所有支持locale的预编译local数据
		locales-all \
		#Mesa 3D是一个在MIT许可证下开放源代码的三维计算机图形库，以开源形式实现了OpenGL的应用程序接口
		mesa-utils mesa-utils-extra \
		#进程工具
		procps psmisc \
		#xdg-utils是一组工具的结合，用于将应用程序轻松地与用户的桌面环境集成
		xdg-utils \
		#X Window系统
		x11-xkb-utils x11-xserver-utils \
	&& /cleanup
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y equivs \
	&& echo "Section: misc\nPriority: optional\nStandards-Version: 3.9.2\nPackage: deepin-user-experience-daemon\nVersion: 99.0\nProvides: deepin-user-experience-daemon\n" > deepin-user-experience-daemon \
	&& equivs-build deepin-user-experience-daemon \
	&& env DEBIAN_FRONTEND=noninteractive apt-get install -y ./deepin-user-experience-daemon_99.0_all.deb \
	&& apt-get remove -y equivs \
	&& rm deepin-user-experience* \
	&& /cleanup
#安装Deepin桌面环境
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    dde-control-center dde-clipboard dde-desktop dde-dock dde-file-manager dde-kwin dde-launcher dde-qt5integration \
    deepin-artwork deepin-default-settings deepin-desktop-base deepin-wallpapers fonts-noto startdde \
    && /cleanup
#安装Deepin应用
RUN apt-get update && env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    dde-calendar deepin-album deepin-calculator deepin-draw deepin-editor deepin-image-viewer \
    deepin-movie deepin-music deepin-screenshot deepin-system-monitor deepin-terminal deepin-voice-note oneko sudo \
    && /cleanup

CMD ["/bin/bash"]