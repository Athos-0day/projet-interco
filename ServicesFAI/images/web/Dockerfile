FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        nginx \
        iproute2 iputils-ping net-tools curl \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
