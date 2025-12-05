FROM ubuntu:24.04
LABEL org.opencontainers.image.source="https://github.com/vossab/webwork-pg-renderer"
LABEL maintainer="Neil Voss (@vossab) <https://github.com/vossab>"

WORKDIR /usr/app
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago
# Ensure Perl finds PG, WeBWorK, and app libs.
ENV PERL5LIB=/usr/app/lib/PG:/usr/app/lib/WeBWorK/lib:/usr/app/lib:$PERL5LIB

# OS/system-level deps and XS-heavy Perl modules (prefer apt for these)
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
    build-essential \
    cpanminus \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/*

# Additional Perl libs available via apt (distro-managed versions are fine here)
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
COPY cpanfile /usr/app/

# App-level Perl deps (pin via cpanfile) go into /usr/app/local
RUN cpanm --notest --installdeps -L /usr/app/local . \
    && rm -rf /root/.cpanm /tmp/*

# Install npm deps using package manifests only (cacheable)
WORKDIR /usr/app/lib/WeBWorK/htdocs
COPY lib/WeBWorK/htdocs/package*.json /usr/app/lib/WeBWorK/htdocs/
RUN npm install

WORKDIR /usr/app/lib/PG/htdocs
COPY lib/PG/htdocs/package*.json /usr/app/lib/PG/htdocs/
COPY lib/PG/htdocs/generate-assets.js lib/PG/htdocs/third-party-assets.json /usr/app/lib/PG/htdocs/
COPY lib/PG/htdocs/js /usr/app/lib/PG/htdocs/js
RUN npm install

# Now copy the full repo (changes here won't invalidate cpanm/npm layers)
WORKDIR /usr/app
COPY . /usr/app

EXPOSE 3000

# Ensure TikZImage shim is present in the image (sometimes omitted by upstream PG).
RUN mkdir -p /usr/app/lib/PG
COPY lib/PG/TikZImage.pm /usr/app/lib/PG/TikZImage.pm

#HEALTHCHECK CMD curl -I localhost:3000/health
CMD hypnotoad -f ./script/render_app
