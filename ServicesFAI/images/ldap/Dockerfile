FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN echo "slapd slapd/no_configuration boolean false" | debconf-set-selections \
    && echo "slapd slapd/domain string fai.lab" | debconf-set-selections \
    && echo "slapd shared/organization string FAI Lab" | debconf-set-selections \
    && echo "slapd slapd/password1 password adminpass" | debconf-set-selections \
    && echo "slapd slapd/password2 password adminpass" | debconf-set-selections \
    && echo "slapd slapd/backend select MDB" | debconf-set-selections \
    && echo "slapd slapd/purge_database boolean true" | debconf-set-selections \
    && echo "slapd slapd/move_old_database boolean true" | debconf-set-selections \
    && echo "slapd slapd/allow_ldap_v2 boolean false" | debconf-set-selections \
    && echo "slapd slapd/dump_database select when needed" | debconf-set-selections \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        slapd ldap-utils \
        iproute2 iputils-ping net-tools \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
