FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1

RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-session \
    xorg \
    tigervnc-standalone-server \
    tigervnc-tools \
    novnc \
    websockify \
    dbus-x11 \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xterm \
    sudo \
    wget \
    unzip \
    curl \
    zenity \
    openjdk-8-jre \
    && apt-get purge -y xfce4-power-manager \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install MicroEmulator
RUN wget -q -O /tmp/microemu.zip \
https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/microemu/microemulator-2.0.4.zip \
&& unzip /tmp/microemu.zip -d /opt/microemulator \
&& rm /tmp/microemu.zip

# Download Avatar
RUN wget -q -O /opt/microemulator/avatar.jar \
https://files.catbox.moe/6q19o1.zip

# Desktop
RUN mkdir -p /root/Desktop

RUN cat >/root/Desktop/microemulator.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=MicroEmulator
Exec=java -Xms64m -Xmx128m -jar -noverify /opt/microemulator/microemulator-2.0.4/microemulator.jar /opt/microemulator/avatar.jar
Terminal=false
Icon=applications-games
EOF

RUN chmod +x /root/Desktop/microemulator.desktop

# VNC
RUN mkdir -p /root/.vnc

RUN echo "123456" | vncpasswd -f > /root/.vnc/passwd \
 && chmod 600 /root/.vnc/passwd

RUN cat >/root/.vnc/xstartup <<EOF
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
[ -r \$HOME/.Xresources ] && xrdb \$HOME/.Xresources
exec dbus-launch --exit-with-session startxfce4
EOF

RUN chmod +x /root/.vnc/xstartup

# Hidden Password Script
RUN cat >/usr/local/bin/ganti-password <<'EOF'
#!/bin/bash

NEWPASS=$(zenity --password --title="Password Baru")
[ -z "$NEWPASS" ] && exit 1

CONFIRM=$(zenity --password --title="Konfirmasi Password")

if [ "$NEWPASS" != "$CONFIRM" ]; then
    zenity --error --text="Password tidak sama!"
    exit 1
fi

mkdir -p /root/.vnc

echo "$NEWPASS" | vncpasswd -f > /root/.vnc/passwd
chmod 600 /root/.vnc/passwd

tigervncserver -kill :1 >/dev/null 2>&1 || true

rm -f /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1

tigervncserver :1 \
-geometry 800x600 \
-depth 24 \
-localhost no

zenity --info --text="Password berhasil diganti."
EOF

RUN chmod +x /usr/local/bin/ganti-password

# Desktop Shortcut
RUN cat >/root/Desktop/ganti-password.desktop <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Ganti Password VNC
Exec=/usr/local/bin/ganti-password
Icon=system-lock-screen
Terminal=false
EOF

RUN chmod +x /root/Desktop/ganti-password.desktop

# Startup
RUN cat >/root/start.sh <<'EOF'
#!/bin/bash

mkdir -p /root/.vnc
touch /root/.Xauthority

tigervncserver -kill :1 >/dev/null 2>&1 || true

rm -f /tmp/.X1-lock
rm -rf /tmp/.X11-unix/X1

tigervncserver :1 \
-geometry 800x600 \
-depth 24 \
-localhost no

sleep 3

websockify \
--web=/usr/share/novnc \
6080 \
localhost:5901 &

tail -f /dev/null
EOF

RUN chmod +x /root/start.sh

EXPOSE 6080

CMD ["/bin/bash","/root/start.sh"]
