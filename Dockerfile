FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=root

RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    tigervnc-tools \
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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install MicroEmulator
RUN wget -q -O /tmp/microemu.zip https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/microemu/microemulator-2.0.4.zip \
    && unzip /tmp/microemu.zip -d /opt/microemulator \
    && rm /tmp/microemu.zip

# Download Avatar
RUN wget -q -O /opt/microemulator/avatar.jar https://files.catbox.moe/9wzwpo.zip

# Setup Desktop
RUN mkdir -p /root/Desktop

RUN cat > /root/Desktop/microemulator.desktop <<EOF
[Desktop Entry]
Type=Application
Name=MicroEmulator
Exec=java -Xms64m -Xmx128m -XX:+UseSerialGC -jar /opt/microemulator/microemulator-2.0.4/microemulator.jar /opt/microemulator/avatar.jar
Icon=applications-games
Terminal=false
EOF

RUN chmod +x /root/Desktop/microemulator.desktop

# Setup VNC
RUN mkdir -p /root/.vnc

RUN echo '#!/bin/bash' > /root/.vnc/xstartup \
 && echo 'unset SESSION_MANAGER' >> /root/.vnc/xstartup \
 && echo 'unset DBUS_SESSION_BUS_ADDRESS' >> /root/.vnc/xstartup \
 && echo 'startxfce4 &' >> /root/.vnc/xstartup \
 && chmod +x /root/.vnc/xstartup

RUN echo "123456" | vncpasswd -f > /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

# Script Ganti Password
RUN cat > /root/Desktop/ganti-password.sh <<'EOF'
#!/bin/bash

NEWPASS=$(zenity --password --title="Password Baru")

if [ -z "$NEWPASS" ]; then
    exit 1
fi

CONFIRM=$(zenity --password --title="Konfirmasi Password")

if [ "$NEWPASS" != "$CONFIRM" ]; then
    zenity --error --text="Password tidak sama!"
    exit 1
fi

mkdir -p /root/.vnc

echo "$NEWPASS" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

tigervncserver -kill :1 >/dev/null 2>&1

rm -rf /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1

tigervncserver :1 \
    -geometry 800x600 \
    -depth 16 \
    -localhost no

zenity --info --text="Password berhasil diganti."
EOF

RUN chmod +x /root/Desktop/ganti-password.sh

RUN cat > /root/Desktop/ganti-password.desktop <<EOF
[Desktop Entry]
Type=Application
Name=Ganti Password VNC
Exec=/root/Desktop/ganti-password.sh
Icon=system-lock-screen
Terminal=false
EOF

RUN chmod +x /root/Desktop/ganti-password.desktop

# Startup Script
RUN cat > /root/start.sh <<'EOF'
#!/bin/bash

mkdir -p /root/.vnc

tigervncserver -kill :1 >/dev/null 2>&1

rm -rf /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1

tigervncserver :1 \
    -geometry 800x600 \
    -depth 16 \
    -localhost no

websockify \
    --web=/usr/share/novnc \
    6080 \
    localhost:5901 &

tail -f /dev/null
EOF

RUN chmod +x /root/start.sh

EXPOSE 6080

CMD ["/bin/bash","/root/start.sh"]
