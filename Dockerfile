FROM rakudo-star

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm-256color

WORKDIR /srv

RUN apt-get update -q && \
    apt-get install --no-install-recommends -qy \
        apt-transport-https \
        apt-utils \
        ca-certificates \
        gnupg2 \
        wget && \

    sh -c 'echo deb https://packages.sury.org/php/ jessie main | tee /etc/apt/sources.list.d/sury.list' && \
    wget -q -O- https://packages.sury.org/php/apt.gpg | apt-key add - && \

    apt-get update -q && \
    apt-get install --no-install-recommends -qy \
        git \
        libssl-dev \
        unzip \
        vim-nox \
        zip && \

    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY . .

RUN echo "Installing Bailador dependencies..." && \
    zef --deps-only install .

CMD ["/bin/bash"]
