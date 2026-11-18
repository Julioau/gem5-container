FROM docker.io/library/ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN set -e; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        python2.7 \
        libpython2.7 \
        zlib1g \
        gcc \
        g++ \
        libc6-dev \
        make \
        file \
        less \
        nano \
        vim-tiny \
        sudo; \
    ln -sf /usr/bin/python2.7 /usr/bin/python; \
    useradd -m -s /bin/bash -G sudo orgb; \
    echo "orgb:orgb" | chpasswd; \
    mkdir -p /home/orgb/gem5; \
    chown orgb:orgb /home/orgb/gem5; \
    rm -rf /var/lib/apt/lists/*

USER orgb
WORKDIR /home/orgb/gem5

COPY --chown=orgb:orgb build /home/orgb/gem5/build
COPY --chown=orgb:orgb configs /home/orgb/gem5/configs
COPY --chown=orgb:orgb tests /home/orgb/gem5/tests
COPY --chown=orgb:orgb orgb_configs /home/orgb/gem5/orgb_configs
COPY --chown=orgb:orgb orgb_progs /home/orgb/gem5/orgb_progs
COPY --chown=orgb:orgb COPYING LICENSE README parsetab.py gem5 /home/orgb/gem5/

CMD ["/bin/bash"]
