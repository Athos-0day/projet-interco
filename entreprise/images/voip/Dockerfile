# Use the Debian base image
FROM debian:stable-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for building Asterisk
RUN apt-get update && \
    apt-get install -y \
    build-essential \
    wget \
    curl \
    libncurses5-dev \
    libxml2-dev \
    uuid-dev \
    libjansson-dev \
    libssl-dev \
    libedit-dev \
    libsqlite3-dev \
    libxslt1-dev \
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
    wget && \
    apt-get clean


# Download Asterisk source code
RUN curl -L -o /tmp/asterisk.tar.gz https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-23.1.0.tar.gz && \
    tar -xzvf /tmp/asterisk.tar.gz -C /tmp/ && \
    rm /tmp/asterisk.tar.gz

# Build and install Asterisk
WORKDIR /tmp/asterisk-23.1.0
RUN ./configure && \
    make && \
    make install && \
    make config && \
    ldconfig && \
    rm -rf /tmp/asterisk-23.1.0

# Expose the necessary ports for SIP and RTP
# EXPOSE 5060/udp 10000-20000/udp

# Start Asterisk when the container runs
# CMD ["/usr/sbin/asterisk", "-f"]

RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
CMD ["/bin/bash"]
