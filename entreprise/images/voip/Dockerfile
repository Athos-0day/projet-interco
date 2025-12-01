FROM debian:stable-slim

# Mise à jour et installation
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        asterisk \
        iproute2 \
        iptables \
        net-tools \
        nano \
        iputils-ping && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
CMD ["/bin/bash"]
