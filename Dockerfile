FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV USER=root

RUN apt update -y && apt install --no-install-recommends -y \
    lxde-core \
    tightvncserver \
    novnc \
    websockify \
    openjdk-8-jre \
    wget \
    unzip \
    xvfb \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN wget -q https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/microemu/microemulator-2.0.4.zip \
    && unzip microemulator-2.0.4.zip -d /opt/microemulator \
    && rm microemulator-2.0.4.zip

RUN wget -q https://files.catbox.moe/9wzwpo.zip \
    && mv 9wzwpo.zip /opt/microemulator/avatar.jar

RUN mkdir -p /root/Desktop && echo '[Desktop Entry]' > /root/Desktop/microemulator.desktop \
    && echo 'Type=Application' >> /root/Desktop/microemulator.desktop \
    && echo 'Name=MicroEmulator' >> /root/Desktop/microemulator.desktop \
    && echo 'Exec=java -Xmx64m -Xms32m -XX:+UseSerialGC -jar /opt/microemulator/microemulator-2.0.4/microemulator.jar /opt/microemulator/avatar.jar' >> /root/Desktop/microemulator.desktop \
    && echo 'Icon=applications-games' >> /root/Desktop/microemulator.desktop \
    && echo 'Terminal=false' >> /root/Desktop/microemulator.desktop \
    && chmod +x /root/Desktop/microemulator.desktop

RUN mkdir -p /root/.vnc && echo "#!/bin/sh" > /root/.vnc/xstartup \
    && echo "xrdb \$HOME/.Xresources" >> /root/.vnc/xstartup \
    && echo "startlxde &" >> /root/.vnc/xstartup \
    && chmod +x /root/.vnc/xstartup

RUN echo "123456" | vncpasswd -f > /root/.vnc/passwd && chmod 600 /root/.vnc/passwd

EXPOSE 6080

CMD bash -c " \
    rm -rf /tmp/.X1-lock /tmp/.X11-unix/X1 && \
    Xvfb :1 -screen 0 640x480x16 -ac & \
    sleep 3 && \
    pkill -f tightvncserver || true && \
    tightvncserver :1 -geometry 640x480 -depth 16 -rfbauth /root/.vnc/passwd -localhost no && \
    websockify --web=/usr/share/novnc 0.0.0.0:6080 localhost:5901 & \
    tail -f /dev/null"
