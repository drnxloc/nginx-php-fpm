FROM debian:bullseye-slim

LABEL maintainer="Loc Nguyen work@drnxloc.dev"

# PHP 8.4.4
# Let the container know that there is no tty
ENV DEBIAN_FRONTEND=noninteractive
ENV NGINX_VERSION=1.27.4-1~bullseye
ENV PHP_VERSION=8.4  
ENV php_conf=/etc/php/${PHP_VERSION}/fpm/php.ini
ENV fpm_conf=/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
ENV COMPOSER_VERSION=2.8.6

# Install basic dependencies
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
        curl gcc make autoconf libc-dev zlib1g-dev pkg-config \
        gnupg2 dirmngr wget apt-transport-https lsb-release ca-certificates

# Add Nginx and PHP repositories
RUN NGINX_GPGKEY=573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62; \
    found=''; \
    for server in \
    ha.pool.sks-keyservers.net \
    hkp://keyserver.ubuntu.com:80 \
    hkp://p80.pool.sks-keyservers.net:80 \
    pgp.mit.edu \
    ; do \
    echo "Fetching GPG key $NGINX_GPGKEY from $server"; \
    apt-key adv --batch --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$NGINX_GPGKEY" && found=yes && break; \
    done; \
    test -z "$found" && echo >&2 "error: failed to fetch GPG key $NGINX_GPGKEY" && exit 1; \
    echo "deb http://nginx.org/packages/mainline/debian/ $(lsb_release -sc) nginx" >> /etc/apt/sources.list \
    && wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg \
    && echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Install Nginx, PHP and other utilities
RUN apt-get update \
    && apt-get install --no-install-recommends --no-install-suggests -q -y \
        apt-utils \
        build-essential \
        nano \
        zip \
        unzip \
        python3-pip \
        python3-setuptools \
        git \
        libmemcached-dev \
        libmemcached11 \
        libmagickwand-dev \
        libuv1-dev \
        nginx=${NGINX_VERSION} \
        php${PHP_VERSION}-fpm \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-dev \
        php${PHP_VERSION}-common \
        php${PHP_VERSION}-opcache \
        php${PHP_VERSION}-readline \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-gd \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-imagick \
        php-pear \
        cron

# Install PHP extensions and create directories
RUN pecl channel-update pecl.php.net && pecl -d php_suffix=${PHP_VERSION} install -o -f redis memcached openswoole-25.2.0 uv \
    && mkdir -p /run/php

# Install Python packages
RUN pip install wheel \
    && pip install supervisor \
    && pip install git+https://github.com/coderanger/supervisor-stdout

# Configure PHP and PHP-FPM
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d \
    && rm -rf /etc/nginx/conf.d/default.conf \
    && sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" ${php_conf} \
    && sed -i -e "s/memory_limit\s*=\s*.*/memory_limit = 256M/g" ${php_conf} \
    && sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" ${php_conf} \
    && sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" ${php_conf} \
    && sed -i -e "s/variables_order = \"GPCS\"/variables_order = \"EGPCS\"/g" ${php_conf} \
    && sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php/${PHP_VERSION}/fpm/php-fpm.conf \
    && sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_children = 5/pm.max_children = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.start_servers = 2/pm.start_servers = 3/g" ${fpm_conf} \
    && sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 4/g" ${fpm_conf} \
    && sed -i -e "s/pm.max_requests = 500/pm.max_requests = 200/g" ${fpm_conf} \
    && sed -i -e "s/www-data/nginx/g" ${fpm_conf} \
    && sed -i -e "s/^;clear_env = no$/clear_env = no/" ${fpm_conf}

# Configure PHP extensions
RUN echo "extension=redis.so" > /etc/php/${PHP_VERSION}/mods-available/redis.ini \
    && echo "extension=memcached.so" > /etc/php/${PHP_VERSION}/mods-available/memcached.ini \
    && echo "extension=imagick.so" > /etc/php/${PHP_VERSION}/mods-available/imagick.ini \
    && echo "extension=openswoole.so" > /etc/php/${PHP_VERSION}/mods-available/openswoole.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/redis.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-redis.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/redis.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-redis.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/memcached.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-memcached.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/memcached.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-memcached.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/imagick.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-imagick.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/imagick.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-imagick.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/openswoole.ini /etc/php/${PHP_VERSION}/fpm/conf.d/20-openswoole.ini \
    && ln -sf /etc/php/${PHP_VERSION}/mods-available/openswoole.ini /etc/php/${PHP_VERSION}/cli/conf.d/20-openswoole.ini

# Install Composer
RUN curl -o /tmp/composer-setup.php https://getcomposer.org/installer \
    && curl -o /tmp/composer-setup.sig https://composer.github.io/installer.sig \
    && php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" \
    && php /tmp/composer-setup.php --no-ansi --install-dir=/usr/local/bin --filename=composer --version=${COMPOSER_VERSION} \
    && rm -rf /tmp/composer-setup.php

# Set Node.js version
ENV NODE_MAJOR=22

# Install Node.js
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -q -y \
    ca-certificates gnupg2 && \
    mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && apt-get install --no-install-recommends --no-install-suggests -q -y nodejs

# Optimize images
RUN apt-get update && apt-get install --no-install-recommends --no-install-suggests -q -y \
    jpegoptim \
    optipng \
    pngquant \
    gifsicle \
    webp \
    libavif-bin \
    && npm install -g svgo

# Clean up
RUN apt-get purge -y --auto-remove gcc make autoconf libc-dev zlib1g-dev pkg-config \
    && apt-get clean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/* /tmp/pear

# Supervisor config
COPY ./supervisord.conf /etc/supervisord.conf

# Override nginx's default config
COPY ./default.conf /etc/nginx/conf.d/default.conf
COPY ./options-ssl-nginx.conf /etc/nginx/options-ssl-nginx.conf
# Override default nginx welcome page
COPY html /usr/share/nginx/html

# Copy Scripts
COPY ./start.sh /start.sh

EXPOSE 80

CMD ["/start.sh"]
