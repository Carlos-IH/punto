FROM php:8.5.12-apache

LABEL maintainer="jekkos"

ENV PHP_TIMEZONE=America/Mexico_City

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libicu-dev \
        libgd-dev \
        unzip \
    && docker-php-ext-install mysqli bcmath intl gd \
    && rm -f /etc/apache2/mods-enabled/mpm_*.load \
        /etc/apache2/mods-enabled/mpm_*.conf \
    && a2enmod mpm_prefork rewrite \
    && test "$(apache2ctl -M 2>&1 | awk '/mpm_[^ ]+_module/ { count++ } END { print count + 0 }')" -eq 1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=composer:2 /usr/bin/composer /usr/local/bin/composer

COPY composer.json composer.lock ./

RUN composer install \
    --no-dev \
    --no-interaction \
    --prefer-dist \
    --no-progress \
    --optimize-autoloader

COPY docker/railway-entrypoint.sh /usr/local/bin/railway-entrypoint.sh

RUN chmod 755 /usr/local/bin/railway-entrypoint.sh

COPY . /app

RUN chown -R root:www-data /app \
    && chmod -R go-w,o= /app \
    && chown -R www-data:www-data /app/writable /app/public/uploads \
    && chmod 750 \
        /app/writable/logs \
        /app/writable/uploads \
        /app/writable/cache \
        /app/public/uploads \
        /app/public/uploads/item_pics \
    && chmod 640 /app/writable/uploads/importCustomers.csv \
    && ln -s /app/*[^public] /var/www \
    && rm -rf /var/www/html \
    && ln -nsf /app/public /var/www/html

EXPOSE 80

CMD ["railway-entrypoint.sh"]
