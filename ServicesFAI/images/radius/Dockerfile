FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        freeradius freeradius-ldap freeradius-utils \
        iproute2 iputils-ping net-tools \
        procps \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
