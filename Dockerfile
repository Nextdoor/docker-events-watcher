FROM ubuntu@sha256:e348fbbea0e0a0e73ab0370de151e7800684445c509d46195aef73e090a49bd6

ENV VERSION "17.03.1-ce"
RUN apt-get update && \
	apt-get install bash curl jq iproute2 net-tools -y && \
    curl -L -o /tmp/docker-$VERSION.tgz https://download.docker.com/linux/static/stable/x86_64/docker-$VERSION.tgz && \
    tar -xz -C /tmp -f /tmp/docker-$VERSION.tgz && \
    mv /tmp/docker/docker /usr/bin && \
    rm -rf /tmp/docker-$VERSION /tmp/docker && \
    apt-get autoremove --purge -y && \
    rm -rf /var/lib/apt/lists/*

ADD . /app

CMD ["/app/entrypoint.sh"]
