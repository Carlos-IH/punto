FROM php:8.2-apache

LABEL maintainer="jekkos"

ENV PHP_TIMEZONE=America/Mexico_City

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        libicu-dev \
        libgd-dev \
        unzip \
    && docker-php-ext-install mysqli bcmath intl gd \
    && (a2dismod mpm_event mpm_worker mpm_prefork || true) \
    && a2enmod mpm_prefork rewrite \
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

CMD ["sh", "-c", "if [ -z \"${ALLOWED_HOSTNAMES:-}\" ] && [ -n \"${RAILWAY_PUBLIC_DOMAIN:-}\" ]; then export ALLOWED_HOSTNAMES=\"$RAILWAY_PUBLIC_DOMAIN\"; fi; php spark env:provision && exec apache2-foreground"]
