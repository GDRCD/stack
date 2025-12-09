# Create image based on the official PHP-FMP image
FROM php:8.0-fpm-alpine AS base-stage

# Arguments defined in docker-compose.yml
ARG uid

# Update the base libraries
RUN apk update && apk upgrade

# Install useful tools and install important libaries
RUN apk add --no-cache \
    git nano wget dialog bash \
    build-base \
    gettext-dev \
    zip openssl curl \
    libmcrypt \
    freetype \
    freetype-dev \
    libjpeg-turbo-dev \
    libjpeg-turbo \
    libpng \
    libxpm \
    sqlite-dev \
    mariadb-client \
    libpng-dev \
    zlib-dev \
    libzip-dev \
    icu-dev \
    libwebp-dev \
    oniguruma-dev \
    curl-dev \
    libmemcached-dev

# Other PHP Extensions
RUN echo "Installing PHP extensions" && \
    docker-php-ext-install pdo pdo_mysql mysqli curl tokenizer zip mbstring gettext opcache && \
    docker-php-ext-configure \
        # ref: https://github.com/docker-library/php/issues/920#issuecomment-562864296
        gd --enable-gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install gd

# Other PHP Extensions
RUN echo "Enabling PHP extensions" && \
    docker-php-ext-enable pdo_mysql && \
    docker-php-ext-enable pdo && \
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