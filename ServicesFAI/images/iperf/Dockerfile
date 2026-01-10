FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        iperf3 iproute2 iputils-ping \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
