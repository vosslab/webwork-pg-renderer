FROM ubuntu:24.04
LABEL org.opencontainers.image.source=https://github.com/openwebwork/renderer
MAINTAINER openwebwork

WORKDIR /usr/app
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    apt-utils \
    git \
    gcc \
    npm \
    make \
    curl \
    nodejs \
    dvipng \
    openssl \
    libc-dev \
    cpanminus \
    libssl-dev \
    zlib1g-dev \
    imagemagick \
    ca-certificates \
    texlive-pictures \
    texlive-latex-base \
    texlive-latex-recommended \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/*

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    libgd-perl \
    libdbi-perl \
    libjson-perl \
    libcgi-pm-perl \
    libjson-xs-perl \
    libstorable-perl \
    libtimedate-perl \
    libdatetime-perl \
    libcrypt-jwt-perl \
    libuuid-tiny-perl \
    libtie-ixhash-perl \
    libhttp-async-perl \
    libnet-ssleay-perl \
    libarchive-zip-perl \
    libmojolicious-perl \
    libyaml-libyaml-perl \
    libcrypt-ssleay-perl \
    libio-socket-ssl-perl \
    libclass-accessor-perl \
    libstatistics-r-io-perl \
    libfuture-asyncawait-perl \
    libstring-shellquote-perl \
    libextutils-cbuilder-perl \
    libproc-processtable-perl \
    libmath-random-secure-perl \
    libdata-structure-util-perl \
    liblocale-maketext-lexicon-perl \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/*

#RUN cpanm install \
#    Mojo::Base Statistics::R::IO::Rserve Date::Format \
#    Future::AsyncAwait Crypt::JWT IO::Socket::SSL CGI::Cookie \
#    Mojo::IOLoop::Subprocess \
#    && rm -fr ./cpanm /root/.cpanm /tmp/*

WORKDIR /usr/app
#RUN git config --global advice.detachedHead false
RUN git clone --depth=1 https://github.com/vosslab/webwork-pg-renderer.git /usr/app

WORKDIR /usr/app/lib/WeBWorK/htdocs
RUN npm install

WORKDIR /usr/app/lib/PG/htdocs
RUN npm install

WORKDIR /usr/app

EXPOSE 3000

#HEALTHCHECK CMD curl -I localhost:3000/health
CMD hypnotoad -f ./script/render_app
