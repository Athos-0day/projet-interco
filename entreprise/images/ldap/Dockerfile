FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

ENV LDAP_ORGANISATION="Example Corp"
ENV LDAP_DOMAIN="example.com"
ENV LDAP_ADMIN_PASSWORD="adminpassword"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        slapd ldap-utils \
        iproute2 iptables apt-utils net-tools systemd \
        telnet iputils-ping nano tcpdump inetutils-traceroute \
        isc-dhcp-client dnsutils wget && \
    rm -rf /var/lib/apt/lists/*

# Préconfiguration slapd
RUN echo "slapd slapd/no_configuration boolean false" | debconf-set-selections && \
    echo "slapd slapd/domain string ${LDAP_DOMAIN}" | debconf-set-selections && \
    echo "slapd shared/organization string ${LDAP_ORGANISATION}" | debconf-set-selections && \
    echo "slapd slapd/password1 password ${LDAP_ADMIN_PASSWORD}" | debconf-set-selections && \
    echo "slapd slapd/password2 password ${LDAP_ADMIN_PASSWORD}" | debconf-set-selections && \
    dpkg-reconfigure -f noninteractive slapd

RUN mkdir /etc/scripts
ENV PATH "/etc/scripts:$PATH"
CMD ["/bin/bash"]