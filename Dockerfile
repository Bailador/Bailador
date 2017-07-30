FROM rakudo-star

WORKDIR /srv

COPY . .

RUN echo "===> Installing: Bailador dependencies" && \
    zef --depsonly install .

CMD ["/bin/bash"]
