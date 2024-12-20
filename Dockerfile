FROM kasmweb/core-ubuntu-noble:1.16.1-rolling-weekly

# set version label
ARG BUILD_DATE
ARG VERSION
ARG OBSIDIAN_VERSION
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="quietsy"

ENV HOME /home/kasm-default-profile
ENV STARTUPDIR /dockerstartup
ENV INST_SCRIPTS $STARTUPDIR/install
ENV OBSIDIAN_VERSION=${OBSIDIAN_VERSION}
WORKDIR $HOME

USER root

# title
ENV TITLE=Obsidian

RUN curl -o \
    /usr/share/backgrounds/bg_default.png \
    https://raw.githubusercontent.com/linuxserver/docker-templates/master/linuxserver.io/img/obsidian-logo.png && \
  apt-get update && \
  DEBIAN_FRONTEND=noninteractive \
  apt-get install -y --no-install-recommends \
    chromium-browser \
    chromium-browser-l10n \
    git \
    libgtk-3-bin \
    libatk1.0 \
    libatk-bridge2.0 \
    libnss3 \
    python3-xdg && \
  mkdir /opt && \
  cd /tmp && \
  if [ -z ${OBSIDIAN_VERSION+x} ]; then \
    OBSIDIAN_VERSION=$(curl -sX GET "https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  curl -o \
    /tmp/obsidian.app -L \
    "https://github.com/obsidianmd/obsidian-releases/releases/download/${OBSIDIAN_VERSION}/Obsidian-$(echo ${OBSIDIAN_VERSION} | sed 's/v//g').AppImage" && \
  chmod +x /tmp/obsidian.app && \
  ./obsidian.app --appimage-extract && \
  mv squashfs-root /opt/obsidian && \
  cp \
    /opt/obsidian/usr/share/icons/hicolor/512x512/apps/obsidian.png \
    /usr/share/icons/hicolor/512x512/apps/obsidian.png
    

COPY root/custom_startup.sh $STARTUPDIR/custom_startup.sh
RUN chmod +x $STARTUPDIR/custom_startup.sh
RUN chmod 755 $STARTUPDIR/custom_startup.sh

RUN cp $HOME/.config/xfce4/xfconf/single-application-xfce-perchannel-xml/* $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/
RUN apt-get remove -y xfce4-panel

RUN chown -R 1000:0 $HOME
RUN $STARTUPDIR/set_user_permission.sh $HOME
RUN find /usr/share/ -name "icon-theme.cache" -exec rm -f {} \; && \
    if [ -z ${SKIP_CLEAN+x} ]; then \
      apt-get autoclean; \
      rm -rf \
        /config/.cache \
        /config/.launchpadlib \
        /var/lib/apt/lists/* \
        /var/tmp/* \
        /tmp/*; \
    fi

ENV HOME /home/kasm-user
WORKDIR $HOME
RUN mkdir -p $HOME && chown -R 1000:0 $HOME

USER 1000
