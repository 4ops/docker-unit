FROM 4ops/unit:1.13.0-php-7.2

RUN cp -vf /etc/php/php.ini-production /etc/php/php.ini

COPY ./i.php /app/i.php
COPY --chown=app:app ./unit-config.json /var/lib/unit/conf.json
COPY ./php-config.ini /etc/php/conf.d/phpinfo.ini

USER app
EXPOSE 8000
ENTRYPOINT ["unitd"]
CMD ["--no-daemon"]
