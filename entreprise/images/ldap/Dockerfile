FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# Variables LDAP (à adapter)
ENV LDAP_ORGANISATION="Example Corp"
ENV LDAP_DOMAIN="example.com"
ENV LDAP_ADMIN_PASSWORD="adminpassword"

RUN apt-get update && \
    apt-get install -y slapd ldap-utils && \
    rm -rf /var/lib/apt/lists/*

# Préconfiguration de slapd
RUN echo "slapd slapd/no_configuration boolean false" | debconf-set-selections && \
    echo "slapd slapd/domain string ${LDAP_DOMAIN}" | debconf-set-selections && \
    echo "slapd shared/organization string ${LDAP_ORGANISATION}" | debconf-set-selections && \
    echo "slapd slapd/password1 password ${LDAP_ADMIN_PASSWORD}" | debconf-set-selections && \
    echo "slapd slapd/password2 password ${LDAP_ADMIN_PASSWORD}" | debconf-set-selections && \
    dpkg-reconfigure -f noninteractive slapd

# Ports LDAP / LDAPS
EXPOSE 389 636

# Volumes pour persistance
VOLUME ["/var/lib/ldap", "/etc/ldap/slapd.d"]

CMD ["slapd", "-d", "256", "-h", "ldap:/// ldaps:///"]

