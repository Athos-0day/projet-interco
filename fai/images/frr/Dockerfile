FROM quay.io/frrouting/frr:master
RUN echo 'export PS1="\[\e[38;5;196m\]\u\[\e[38;5;202m\]@\[\e[38;5;208m\]\h \[\e[38;5;220m\]\w \[\033[0m\]$ "' >> /root/.bashrc
RUN echo "alias ip='ip -color=auto'" >> /root/.bashrc
RUN apk add --no-cache accel-ppp dhcp freeradius-client freeradius-utils tcpdump iperf3
# Active OSPF + Zebra (necessaire pour installer les routes dans le kernel)
RUN sed -i 's/ospfd=no/ospfd=yes/g' /etc/frr/daemons \
    && sed -i 's/zebra=no/zebra=yes/g' /etc/frr/daemons
