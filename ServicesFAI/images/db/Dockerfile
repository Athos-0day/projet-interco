FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        mariadb-server mariadb-client \
        iproute2 iputils-ping net-tools \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
