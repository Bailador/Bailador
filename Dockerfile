FROM ubuntu:trusty

ENV RAKUDO_VERSION=2017.07
ENV PATH=$PATH:/opt/rakudo-star-${RAKUDO_VERSION}/bin:/opt/rakudo-star-${RAKUDO_VERSION}/share/perl6/site/bin

RUN echo "===> Installing: System dependencies" && \
        apt-get update && \
        apt-get -y install \
            gcc \
            git \
            make \
            wget && \
    echo "===> Installing: Perl6 Rakudo Star:ver('${RAKUDO_VERSION}')" && \
        cd /tmp && \
        wget https://rakudo.perl6.org/downloads/star/rakudo-star-${RAKUDO_VERSION}.tar.gz && \
        tar xfz rakudo-star-${RAKUDO_VERSION}.tar.gz && \
        cd rakudo-star-${RAKUDO_VERSION} && \
        perl Configure.pl --gen-moar --prefix /opt/rakudo-star-${RAKUDO_VERSION} && \
        make install && \
    echo "===> Installing: Zef" && \
        cd /tmp && \
        git clone https://github.com/ugexe/zef.git && \
        cd zef && \
        perl6 -Ilib bin/zef install . && \
    echo "===> Cleaning up" && \
        rm -rf /tmp/* && \
        apt-get purge -y && \
    echo "===> Installing: Global Perl6 modules" && \
        zef install \
            Path::Iterator \
            TAP::Harness \
            Test::META && \
    echo "===> Installing: Bailador dependencies" && \
        zef --depsonly install .

ENV WORK_DIR /srv
WORKDIR $WORK_DIR

COPY . ${WORK_DIR}/

CMD ["/bin/bash"]
