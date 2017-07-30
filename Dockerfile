FROM ubuntu:trusty

ENV RAKUDO_VERSION=2017.07
ENV PATH=$PATH:/opt/rakudo/bin:/opt/rakudo/share/perl6/site/bin

ENV TEMP_DIR /tmp
WORKDIR $TEMP_DIR

RUN echo "===> Installing: System dependencies" && \
        apt-get update && \
        apt-get -y install \
            gcc \
            git \
            make \
            wget && \
    echo "===> Installing: Perl6 Rakudo Star:ver('${RAKUDO_VERSION}')" && \
        cd ${TEMP_DIR} && \
        wget https://rakudo.perl6.org/downloads/star/rakudo-star-${RAKUDO_VERSION}.tar.gz && \
        tar xzf rakudo-star-${RAKUDO_VERSION}.tar.gz && \
        cd rakudo-star-${RAKUDO_VERSION} && \
        perl Configure.pl --gen-moar --prefix /opt/rakudo && \
        make install && \
    echo "===> Installing: Zef" && \
        cd ${TEMP_DIR} && \
        git clone https://github.com/ugexe/zef.git && \
        cd zef && \
        perl6 -Ilib bin/zef install . && \
    echo "===> Installing: Global Perl6 modules" && \
        cd ${TEMP_DIR} && \
        zef install \
            Path::Iterator \
            TAP::Harness \
            Test::META && \
    echo "===> Cleaning up" && \
        rm -rf ${TEMP_DIR}/* && \
        apt-get purge -y

ENV PROJECT_DIR /srv
WORKDIR $PROJECT_DIR

COPY . ${PROJECT_DIR}/

RUN echo "===> Installing: Bailador dependencies" && \
    zef --depsonly install .

CMD ["/bin/bash"]
