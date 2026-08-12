#!/usr/bin/env bash
set -e

# PHP > Start services
php-fpm -D
nginx -g 'daemon off;'
