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
RUN git config --global advice.detachedHead false

# Clone renderer version 1.2.9 directly into the image
#RUN git clone --depth=1 https://github.com/openwebwork/renderer.git /usr/app
RUN git clone --depth=1 https://github.com/drdrew42/renderer.git /usr/app

# In your Dockerfile:
RUN git clone --depth=1 --branch 5.65.19 https://github.com/codemirror/CodeMirror.git /tmp/codemirror \
    && cp -r /tmp/codemirror/theme /tmp/codemirror/addon /usr/app/lib/WeBWorK/htdocs/js/vendor/codemirror \
    && rm -rf /tmp/codemirror

# After copying in the local monokai.css
RUN sed -i "s|http://codemirror.net/theme/|/webwork2_files/js/vendor/codemirror/theme/|g" /usr/app/templates/columns/editorUI.html.ep

# Clone PG version 2.17 directly into the image
RUN git clone --depth=1 --branch PG-2.17 https://github.com/openwebwork/pg.git /usr/app/lib/PG

WORKDIR /usr/app/lib/WeBWorK/htdocs
RUN npm install

WORKDIR /usr/app/lib/PG/htdocs
RUN npm install

WORKDIR /usr/app

EXPOSE 3000

#HEALTHCHECK CMD curl -I localhost:3000/health
CMD hypnotoad -f ./script/render_app
