    # Create image based on the official PHP-FMP image
FROM php:5.6-fpm-alpine AS base-stage

# Arguments defined in docker-compose.yml
ARG uid

# Update the base libraries
RUN apk update && apk upgrade

# Install useful tools and install important libaries
RUN apk add --no-cache \
    git nano wget dialog bash \
    build-base \
    zip openssl curl \
    libmcrypt libmcrypt-dev\
    libvpx \
    gettext gettext-dev \
    freetype freetype-dev \
    libjpeg-turbo libjpeg-turbo-dev \
    libpng libpng-dev \
    libxpm libxpm-dev\
    libvpx-dev \
    sqlite-dev \
    mariadb-client \
    zlib-dev \
    libzip-dev \
    icu-dev \
    libwebp-dev \
    oniguruma-dev \
    curl-dev \
    libmemcached-dev


# Other PHP Extensions
RUN echo "Installing PHP extensions" && \
    docker-php-ext-install pdo_mysql && \
    docker-php-ext-install pdo_sqlite && \
    docker-php-ext-install mysqli && \
    docker-php-ext-install curl && \
    docker-php-ext-install tokenizer && \
    docker-php-ext-install json && \
    docker-php-ext-install zip && \
    docker-php-ext-install mbstring && \
    docker-php-ext-install gettext && \
    docker-php-ext-install mcrypt  && \
    docker-php-ext-install opcache && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-xpm-dir=/usr/include/ --with-vpx-dir=/usr/include/ && \
    docker-php-ext-install gd

# Other PHP Extensions
RUN echo "Enabling PHP extensions" && \
    docker-php-ext-enable pdo_mysql && \
    docker-php-ext-enable pdo_sqlite && \
    docker-php-ext-enable mysqli && \
    docker-php-ext-enable zip

# Install intl extension
RUN docker-php-ext-configure intl \
    && docker-php-ext-install intl

# Install sendmailer for Mailhog
RUN  curl --location --output /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64  \
     && chmod +x /usr/local/bin/mhsendmail

# Clean up, try to reduce image size
RUN apk del \
    libmcrypt \
    libpng \
    libjpeg-turbo \
    freetype \
    libxpm \
    libvpx \
    build-base \
 && rm -rf /var/cache/apk/* \
 && rm -rf /tmp/*

# -------------------------------------------------------
# SERVE STAGE
# -------------------------------------------------------

# Get API Base Image
FROM base-stage AS serve-stage

# Arguments defined in compose.yml
ARG uid

# Install serve dependencies
RUN apk update && apk add --no-cache \
    nginx \
    memcached

RUN mkdir -p /run/nginx

# Clean up, try to reduce image size
RUN rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Copy nginx config
COPY .docker/services/webserver/config/sites-available/default.nginx /etc/nginx/conf.d/default.conf

# Copy entrypoint
COPY .docker/services/webserver/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN ln -s /usr/local/bin/entrypoint.sh /

# Specify the entrypoint
ENTRYPOINT ["entrypoint.sh"]

# Set working dir
WORKDIR /var/www/html