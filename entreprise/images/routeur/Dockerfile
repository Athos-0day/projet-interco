FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        iproute2 \
        iptables \
        apt-utils \
        net-tools \
        systemd \
        telnet \
        iputils-ping \
        nano \
        tcpdump \
        inetutils-traceroute \
        isc-dhcp-client \
        isc-dhcp-server \
        dnsutils \
        ekiga \
        alsa-utils \
        pulse-audio \
        dbus-x11 \ 
        libcanberra-gtk-module \
        libcanberra-gtk3-module \
        slapd ldap-utils \
        wget && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
CMD ["/bin/bash"]
