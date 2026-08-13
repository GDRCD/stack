# -------------------------------------------------------
# BASE STAGE
# -------------------------------------------------------

# Create image based on the official PHP-FPM image
FROM php:5.6-fpm-alpine AS base-stage

# Arguments defined in compose.yml
ARG uid

# Install useful tools and important libraries
RUN apk add --no-cache \
    git nano wget dialog bash \
    build-base \
    zip openssl curl \
    libmcrypt libmcrypt-dev \
    mariadb-client \
    zlib-dev \
    libzip-dev \
    oniguruma-dev \
    curl-dev

# Other PHP Extensions
RUN docker-php-ext-install -j"$(nproc)" \
        mysqli curl zip mbstring mcrypt opcache

# Install sendmailer for Mailhog
RUN  curl --location --output /usr/local/bin/mhsendmail https://github.com/mailhog/mhsendmail/releases/download/v0.2.0/mhsendmail_linux_amd64  \
     && chmod +x /usr/local/bin/mhsendmail

# -------------------------------------------------------
# SERVE STAGE
# -------------------------------------------------------

# Get API Base Image
FROM base-stage AS serve-stage

# Arguments defined in compose.yml
ARG uid

# Install serve dependencies
RUN apk add --no-cache \
    nginx \
    shadow

RUN mkdir -p /run/nginx /etc/nginx/http.d \
 && rm -rf /etc/nginx/conf.d \
 && ln -s /etc/nginx/http.d /etc/nginx/conf.d

# Align www-data with the host user, so files written by PHP stay editable
RUN groupmod -o -g "${uid}" www-data \
 && usermod  -o -u "${uid}" -g "${uid}" www-data

# Set cache directory permissions
RUN mkdir -p /var/www/html/cache && chown www-data:www-data /var/www/html/cache

# Copy entrypoint
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
RUN ln -s /usr/local/bin/entrypoint.sh /

# Specify the entrypoint
ENTRYPOINT ["entrypoint.sh"]

# Set working dir
WORKDIR /var/www/html
