FROM fedora:latest
LABEL maintainer="bryanroessler@gmail.com"

RUN dnf install dpkg rpm-build createrepo httpd -y

RUN curl -sO "https://git.bryanroessler.com/bryan/install_MC_fedora/raw/master/install_MC_fedora.sh" \
    && chmod +x ./install_MC_fedora.sh \
    && ./install_MC_fedora.sh -b

RUN dnf clean all

COPY root/ /

RUN systemctl enable httpd build-jriver-repo.timer

EXPOSE 80

CMD [ "/usr/sbin/init" ]

# podman build -t build-jriver-repo .
# podman run -d -p 8081:80 localhost/build-jriver-repo
