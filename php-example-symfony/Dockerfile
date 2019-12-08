FROM php:7.2 AS dependencies

WORKDIR /app

RUN mkdir -p /app/vendor/bin
RUN apt-get update -qq
RUN apt-get install -yqq tzdata $PHPIZE_DEPS

ENV TZ      "UTC"
ENV APP_ENV "prod"
ENV PATH    "/app/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
RUN echo "$TZ" > /etc/timezone

RUN apt-get install -yqq libwebp-dev libjpeg-dev libpng-dev
RUN docker-php-ext-configure gd --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ --with-webp-dir=/usr/include/ > /dev/null
RUN docker-php-ext-install gd > /dev/null

RUN apt-get install -yqq libicu-dev
RUN docker-php-ext-configure intl > /dev/null
RUN docker-php-ext-install intl > /dev/null

RUN docker-php-ext-install opcache > /dev/null

RUN docker-php-ext-install pdo_mysql > /dev/null

RUN apt-get install -yqq libzip-dev
RUN docker-php-ext-configure zip --with-libzip
RUN docker-php-ext-install zip > /dev/null

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

RUN php -m

COPY ./composer.json ./composer.lock ./

RUN composer --no-interaction install --prefer-dist --no-dev \
    && security-checker --no-ansi --no-interaction security:check \
    && php bin/console cache:clear

COPY . .

RUN composer --no-interaction dump-autoload --optimize       \
    && composer --no-interaction run-script post-install-cmd \
    && php bin/console cache:clear                           \
    && du -hs /app

COPY ./docker/entrypoint.sh /usr/bin/docker-entrypoint
RUN chmod 0755 /usr/bin/docker-entrypoint

#
# --- Dev Image
#

FROM dependencies AS dev

RUN cp -vf /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini

ENV APP_ENV "dev"

RUN composer --no-ansi --no-interaction install --prefer-dist \
    && composer --no-interaction dump-autoload --optimize     \
    && composer --no-interaction run-script post-install-cmd  \
    && php bin/console cache:clear                            \
    && du -hs /app

VOLUME ["/app/var/cache"]
VOLUME ["/app/var/log"]

EXPOSE 8000
ENTRYPOINT ["docker-entrypoint"]
CMD ["sh"]

#
# --- App Image
#

FROM 4ops/unit:1.13.0-php-7.2 AS prod

RUN cp -vf /etc/php/php.ini-production /etc/php/php.ini

COPY --from=dependencies /usr/bin/docker-entrypoint /usr/bin/docker-entrypoint
COPY --from=dependencies /app /app
COPY --chown=app:app ./docker/unit-config.json /var/lib/unit/conf.json
COPY --chown=root:app ./docker/php-config.ini /etc/php/conf.d/symfony.ini

RUN chown -R app:app /app

VOLUME ["/app/var/cache"]
VOLUME ["/app/var/log"]

USER app

ENV APP_ENV "prod"
ENV PATH    "/app/vendor/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

RUN php -m

EXPOSE 8000
ENTRYPOINT ["unitd"]
CMD ["--no-daemon"]
