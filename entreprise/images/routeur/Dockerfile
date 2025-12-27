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
        frr \
        frr-pythontools && \
    rm -rf /var/lib/apt/lists/*
# Active OSPF
RUN sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons
RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
CMD ["/bin/bash"]
