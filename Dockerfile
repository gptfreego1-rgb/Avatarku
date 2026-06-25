FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    VNC_RESOLUTION=480x360 \
    VNC_DEPTH=16

RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server novnc websockify \
    sudo xterm init systemd snapd \
    vim net-tools curl wget git tzdata unzip \
    openjdk-8-jre \
    dbus-x11 x11-utils x11-xserver-utils x11-apps \
    xubuntu-icon-theme \
    htop procps \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN wget -q https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/microemu/microemulator-2.0.4.zip \
    && unzip microemulator-2.0.4.zip -d /opt/microemulator \
    && rm microemulator-2.0.4.zip

RUN wget -q https://files.catbox.moe/9wzwpo.zip -O /opt/microemulator/avatar.jar

RUN mkdir -p /root/Desktop && \
    echo '[Desktop Entry]' > /root/Desktop/microemulator.desktop && \
    echo 'Type=Application' >> /root/Desktop/microemulator.desktop && \
    echo 'Name=MicroEmulator' >> /root/Desktop/microemulator.desktop && \
    echo 'Exec=java -noverify -Xmx50m \
        -Dsun.java2d.opengl=false \
        -Dsun.java2d.xrender=false \
        -Dsun.java2d.noddraw=true \
        -Dsun.java2d.pmoffscreen=false \
        -Dawt.useSystemAAFontSettings=off \
        -jar /opt/microemulator/microemulator-2.0.4/microemulator.jar \
        /opt/microemulator/avatar.jar' >> /root/Desktop/microemulator.desktop && \
    echo 'Icon=utilities-terminal' >> /root/Desktop/microemulator.desktop && \
    echo 'Terminal=false' >> /root/Desktop/microemulator.desktop && \
    chmod +x /root/Desktop/microemulator.desktop

RUN mkdir -p /root/.vnc && \
    echo '#!/bin/bash' > /root/.vnc/xstartup && \
    echo 'xrdb $HOME/.Xresources' >> /root/.vnc/xstartup && \
    echo 'startxfce4 &' >> /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

RUN touch /root/.Xauthority

EXPOSE 5901 6080

CMD bash -c "\
    echo '[Tuning] Matikan screensaver & compositing...' && \
    vncserver :1 \
        -localhost no \
        -SecurityTypes None \
        -geometry 480x360 \
        -depth 16 \
        -pixelformat rgb565 \
        -AlwaysShared \
        -DisconnectClients=false \
        -IdleTimeout 0 \
        -ZlibLevel 1 \
        --I-KNOW-THIS-IS-INSECURE && \
    sleep 2 && \
    xset -dpms & \
    xset s off & \
    xfconf-query -c xfwm4 -p /general/use_compositing -s false || true && \
    echo '[Tuning] Generate SSL untuk noVNC...' && \
    openssl req -new -subj '/C=ID' -x509 -days 365 -nodes \
        -out /self.pem -keyout /self.pem 2>/dev/null && \
    echo '[Tuning] Jalankan websockify...' && \
    websockify -D \
        --web=/usr/share/novnc/ \
        --cert=/self.pem \
        --max-fps=30 \
        6080 localhost:5901 && \
    echo '==============================================' && \
    echo 'noVNC siap: http://localhost:6080/vnc.html' && \
    echo 'Resolusi: 480x360 / 16-bit' && \
    echo 'Game: /opt/microemulator/avatar.jar' && \
    echo '==============================================' && \
    tail -f /dev/null"
