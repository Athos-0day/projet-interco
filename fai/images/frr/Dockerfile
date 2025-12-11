FROM frrouting/frr:latest
RUN echo 'export PS1="\[\e[38;5;196m\]\u\[\e[38;5;202m\]@\[\e[38;5;208m\]\h \[\e[38;5;220m\]\w \[\033[0m\]$ "' >> /root/.bashrc
RUN echo "alias ip='ip -color=auto'" >> /root/.bashrc
RUN apk add --no-cache dhcp