# -------------------------------------------------------
# BASE STAGE
# -------------------------------------------------------

# Create image based on the official PHP-FMP image
FROM php:7.3-fpm-alpine AS base-stage

# Update the base libraries
RUN apk update && apk upgrade

# Install useful tools and install important libaries
RUN apk add --no-cache \
    git nano wget dialog bash \
    build-base \
    zip openssl curl \
    gettext gettext-dev \
    libmcrypt libmcrypt-dev \
    freetype freetype-dev \
    libjpeg-turbo libjpeg-turbo-dev \
    libpng \
    libxpm \
    sqlite-dev \
    mariadb-client \
    libzip-dev \
    icu-dev \
    libvpx-dev \
    oniguruma-dev \
    curl-dev \
    libmemcached-dev \
    zlib-dev

# Other PHP Extensions
RUN echo "Installing PHP extensions" && \
    docker-php-ext-install pdo_mysql \
    pdo_sqlite \
    mysqli \
    curl \
    tokenizer \
    json \
    zip \
    mbstring \
    gettext \
    opcache && \
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include && \
    docker-php-ext-install gd

# Other PHP Extensions
RUN echo "Enabling PHP extensions" && \
    docker-php-ext-enable pdo_mysql pdo_sqlite mysqli zip

# Install intl extension
RUN echo "Install PHP Intl" \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-enable intl \
    && rm -rf /tmp/*

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

# Clean up, try to reduce image size
RUN rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Copy nginx config
COPY .docker/services/webserver/config/sites-available/default.nginx /etc/nginx/http.d/default.conf

# Copy entrypoint
COPY .docker/services/webserver/entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN ln -s /usr/local/bin/entrypoint.sh /

# Specify the entrypoint
ENTRYPOINT ["entrypoint.sh"]

# Set working dir
WORKDIR /var/www/html