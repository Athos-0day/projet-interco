# Use the Debian base image
FROM debian:bookworm

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
    libsqlite3-dev && \
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
EXPOSE 5060/udp 10000-20000/udp

# Start Asterisk when the container runs
CMD ["/usr/sbin/asterisk", "-f"]

