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
        slapd \
        ldap-utils \
        alsa-utils \
        dbus-x11 \
        wget && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
CMD ["/bin/bash"]
