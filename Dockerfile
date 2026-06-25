FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    novnc \
    websockify \
    sudo \
    xterm \
    wget \
    unzip \
    openjdk-8-jre \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    zenity \
    && apt clean && rm -rf /var/lib/apt/lists/*

RUN wget -q https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/microemu/microemulator-2.0.4.zip \
    && unzip microemulator-2.0.4.zip -d /opt/microemulator \
    && rm microemulator-2.0.4.zip

RUN wget -q https://files.catbox.moe/9wzwpo.zip \
    && mv 9wzwpo.zip /opt/microemulator/avatar.jar

RUN mkdir -p /root/Desktop && echo '[Desktop Entry]' > /root/Desktop/microemulator.desktop \
    && echo 'Type=Application' >> /root/Desktop/microemulator.desktop \
    && echo 'Name=MicroEmulator' >> /root/Desktop/microemulator.desktop \
    && echo 'Exec=java -Xmx128m -Xms64m -XX:+UseSerialGC -XX:MaxGCPauseMillis=50 -jar /opt/microemulator/microemulator-2.0.4/microemulator.jar /opt/microemulator/avatar.jar' >> /root/Desktop/microemulator.desktop \
    && echo 'Icon=applications-games' >> /root/Desktop/microemulator.desktop \
    && echo 'Terminal=false' >> /root/Desktop/microemulator.desktop \
    && chmod +x /root/Desktop/microemulator.desktop

RUN echo '#!/bin/bash' > /root/Desktop/ganti-password.sh \
    && echo 'NEWPASS=$(zenity --password --title="Ganti Password VNC" --text="Masukkan password baru:" --width=300)' >> /root/Desktop/ganti-password.sh \
    && echo 'if [ -z "$NEWPASS" ]; then' >> /root/Desktop/ganti-password.sh \
    && echo '    zenity --error --text="Password tidak boleh kosong!"' >> /root/Desktop/ganti-password.sh \
    && echo '    exit 1' >> /root/Desktop/ganti-password.sh \
    && echo 'fi' >> /root/Desktop/ganti-password.sh \
    && echo 'CONFIRM=$(zenity --password --title="Konfirmasi Password" --text="Ulangi password baru:" --width=300)' >> /root/Desktop/ganti-password.sh \
    && echo 'if [ "$NEWPASS" != "$CONFIRM" ]; then' >> /root/Desktop/ganti-password.sh \
    && echo '    zenity --error --text="Password tidak cocok!"' >> /root/Desktop/ganti-password.sh \
    && echo '    exit 1' >> /root/Desktop/ganti-password.sh \
    && echo 'fi' >> /root/Desktop/ganti-password.sh \
    && echo 'echo "$NEWPASS" | vncpasswd -f > /root/.vnc/passwd' >> /root/Desktop/ganti-password.sh \
    && echo 'chmod 600 /root/.vnc/passwd' >> /root/Desktop/ganti-password.sh \
    && echo 'vncserver -kill :1' >> /root/Desktop/ganti-password.sh \
    && echo 'sleep 2' >> /root/Desktop/ganti-password.sh \
    && echo 'vncserver :1 -geometry 800x600 -depth 16 -rfbauth /root/.vnc/passwd -localhost no &' >> /root/Desktop/ganti-password.sh \
    && echo 'zenity --info --text="Password berhasil diganti! VNC akan restart otomatis." --width=300' >> /root/Desktop/ganti-password.sh \
    && chmod +x /root/Desktop/ganti-password.sh

RUN echo '[Desktop Entry]' > /root/Desktop/ganti-password.desktop \
    && echo 'Type=Application' >> /root/Desktop/ganti-password.desktop \
    && echo 'Name=Ganti Password VNC' >> /root/Desktop/ganti-password.desktop \
    && echo 'Exec=/root/Desktop/ganti-password.sh' >> /root/Desktop/ganti-password.desktop \
    && echo 'Icon=system-lock-screen' >> /root/Desktop/ganti-password.desktop \
    && echo 'Terminal=false' >> /root/Desktop/ganti-password.desktop \
    && chmod +x /root/Desktop/ganti-password.desktop

RUN mkdir -p /root/.vnc && echo "#!/bin/sh" > /root/.vnc/xstartup \
    && echo "xrdb \$HOME/.Xresources" >> /root/.vnc/xstartup \
    && echo "startxfce4 &" >> /root/.vnc/xstartup \
    && chmod +x /root/.vnc/xstartup

RUN echo "123456" | vncpasswd -f > /root/.vnc/passwd && chmod 600 /root/.vnc/passwd

EXPOSE 6080

CMD bash -c " \
    vncserver :1 -geometry 800x600 -depth 16 -rfbauth /root/.vnc/passwd -localhost no && \
    websockify --web=/usr/share/novnc 0.0.0.0:6080 localhost:5901 & \
    tail -f /dev/null"
