FROM ubuntu:24.04
LABEL org.opencontainers.image.source="https://github.com/vosslab/webwork-pg-renderer"
LABEL maintainer="vosslab (https://bsky.app/profile/neilvosslab.bsky.social)"

WORKDIR /usr/app
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Chicago
ARG INSTALL_OPL=0
ARG OPL_URL=https://github.com/openwebwork/webwork-open-problem-library/archive/refs/heads/master.tar.gz

# OS/system-level deps and XS-heavy Perl modules (prefer apt for these).
RUN printf '#!/bin/sh\nexit 101\n' > /usr/sbin/policy-rc.d \
    && chmod +x /usr/sbin/policy-rc.d \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    git \
    gcc \
    make \
    curl \
    dvipng \
    openssl \
    libc-dev \
    cpanminus \
    libssl-dev \
    libgd-perl \
    zlib1g-dev \
    imagemagick \
    build-essential \
    ca-certificates \
    texlive-latex-recommended \
    texlive-fonts-recommended \
    texlive-pictures \
    tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/*

# Additional Perl libs available via apt (distro-managed versions are fine here).
RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    libdbi-perl \
    libjson-perl \
    libcgi-pm-perl \
    libjson-xs-perl \
    ca-certificates \
    libstorable-perl \
    libdatetime-perl \
    libuuid-tiny-perl \
    libtie-ixhash-perl \
    libhttp-async-perl \
    libnet-ssleay-perl \
    libarchive-zip-perl \
    libcrypt-ssleay-perl \
    libclass-accessor-perl \
    libstring-shellquote-perl \
    libextutils-cbuilder-perl \
    libproc-processtable-perl \
    libmath-random-secure-perl \
    libdata-structure-util-perl \
    liblocale-maketext-lexicon-perl \
    libyaml-libyaml-perl \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends --no-install-suggests nodejs \
    && apt-get clean \
    && rm -fr /var/lib/apt/lists/* /tmp/*

ENV PG_ROOT=/usr/app/lib/PG
ENV PERL5LIB=/usr/app/lib/PG/lib:/usr/app/lib${PERL5LIB:+:$PERL5LIB}

COPY cpanfile /usr/app/cpanfile
COPY lib/PG/cpanfile /usr/app/lib/PG/cpanfile

RUN cpanm --notest --cpanfile /usr/app/lib/PG/cpanfile --installdeps /usr/app/lib/PG \
    && cpanm --notest --cpanfile /usr/app/cpanfile --installdeps /usr/app \
    && rm -fr ./cpanm /root/.cpanm /tmp/*

COPY public/package*.json /usr/app/public/
COPY public/generate-assets.js /usr/app/public/
COPY public/js /usr/app/public/js
COPY public/css /usr/app/public/css
RUN cd /usr/app/public && npm ci

COPY lib/PG/htdocs/package*.json /usr/app/lib/PG/htdocs/
COPY lib/PG/htdocs/generate-assets.js /usr/app/lib/PG/htdocs/
COPY lib/PG/htdocs/js /usr/app/lib/PG/htdocs/js
RUN cd /usr/app/lib/PG/htdocs && npm ci

RUN if [ "$INSTALL_OPL" = "1" ]; then \
    curl -sSL "$OPL_URL" -o /tmp/opl.tar.gz \
    && tar -zxf /tmp/opl.tar.gz -C /tmp \
    && mkdir -p /usr/app/webwork-open-problem-library \
    && mv /tmp/webwork-open-problem-library-master/OpenProblemLibrary /usr/app/webwork-open-problem-library/OpenProblemLibrary \
    && mv /tmp/webwork-open-problem-library-master/Contrib /usr/app/webwork-open-problem-library/Contrib \
    && rm -rf /tmp/webwork-open-problem-library-master /tmp/opl.tar.gz; \
  fi

COPY . .

RUN test -f "$PG_ROOT/lib/WeBWorK/PG.pm"

RUN cp render_app.conf.dist render_app.conf
RUN mkdir -p lib/PG/conf && cp conf/pg_config.yml lib/PG/conf/pg_config.yml

EXPOSE 3000

HEALTHCHECK CMD curl -I localhost:3000/health

CMD hypnotoad -f ./script/render_app
