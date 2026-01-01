FROM debian:stable-slim

# Mise à jour et installation de Nginx + utilitaires
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        nginx \
        iproute2 \
        iptables \
        net-tools \
        nano \
        iputils-ping \
        tcpdump \
        inetutils-traceroute && \
    rm -rf /var/lib/apt/lists/*

# Supprimer le contenu HTML par défaut
RUN rm -rf /var/www/html/*

RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
CMD ["/bin/bash"]
