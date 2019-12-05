FROM alpine:3.10 AS base

RUN set -ex \
  ; apk add --no-cache --quiet \
            argon2-libs \
            bash \
            c-client \
            ca-certificates \
            curl \
            icu-libs \
            freetype \
            gmp \
            krb5-libs \
            libcrypto1.1 \
            libcurl \
            libedit \
            libbz2 \
            libgd \
            libintl \
            libjpeg-turbo \
            libldap \
            libpng \
            libsodium \
            libssl1.1 \
            libtls-standalone \
            libwebp \
            libxml2 \
            libxpm \
            libxslt \
            libzip \
            mysql-client \
            ncurses-libs \
            nghttp2-libs \
            openssl \
            pcre \
            pcre2 \
            sqlite-libs \
            tidyhtml-libs \
            zlib \
            \
   ; addgroup -g 1042 app \
   ; adduser -s /sbin/nologin -G app -u 1042 -D app \
   ; mkdir -p /app /var/lib/unit/certs \
   ; chown -R app:root /var/lib/unit \
   ; ln -sf /dev/stderr /var/log/unit.log \
   ; chmod 0700 /var/lib/unit

# --- Builder

FROM php:7.2-alpine AS builder

RUN apk add --no-cache --quiet \
            argon2-dev \
            autoconf \
            bison \
            busybox-extras \
            busybox-suid \
            bzip2-dev \
            ca-certificates \
            coreutils \
            curl-dev \
            db-dev \
            dpkg \
            dpkg-dev \
            file \
            freetype-dev \
            g++ \
            gcc \
            gd-dev \
            gdbm-dev \
            gettext-dev \
            git \
            gmp-dev \
            icu-dev \
            imap-dev \
            jpeg-dev \
            krb5-dev \
            libc-dev \
            libedit-dev \
            libical-dev \
            libjpeg-turbo-dev \
            libpng-dev \
            libsodium-dev \
            libwebp-dev \
            libxml2-dev \
            libxpm-dev \
            libxslt-dev \
            libzip-dev \
            make \
            musl-dev \
            openldap-dev \
            openssl-dev \
            pcre-dev \
            pkgconf \
            re2c \
            shadow \
            ssmtp \
            sqlite-dev \
            tidyhtml-dev \
            tzdata \
            unzip \
            zlib-dev \
            ;
RUN set -ex \
  ; addgroup -g 1042 app \
  ; adduser -s /sbin/nologin -G app -u 1042 -D app \
  ;
RUN mkdir -p "${PHP_INI_DIR}/conf.d"
RUN docker-php-source extract
RUN curl -sS https://getcomposer.org/installer \
  | php -- --install-dir=/usr/local/bin --filename=composer \
  ;
RUN pecl channel-update pecl.php.net

# --- Dist

FROM builder AS dist

ENV PHP_INI_DIR  "/etc/php"
ENV DESTDIR      "/install"
ENV INSTALL_ROOT "/install"
ENV UNIT_VERSION "1.13.0"

WORKDIR /usr/src/php

RUN export CFLAGS="${PHP_CFLAGS}" \
           CPPFLAGS="${PHP_CPPFLAGS}" \
           LDFLAGS="${PHP_LDFLAGS}"\
           \
  ; ./configure build_alias=x86_64-linux-musl \
                --prefix=/usr \
                --datadir=/usr/share/php \
                --sysconfdir=/etc/php \
                --localstatedir=/var \
                --build=x86_64-linux-musl \
                --enable-option-checking=fatal \
                --enable-embed=shared \
                --disable-phpdbg \
                --disable-short-tags \
                --enable-bcmath=shared \
                --enable-calendar=shared \
                --enable-ctype=shared \
                --enable-dom=shared \
                --enable-exif=shared \
                --enable-fileinfo=shared \
                --enable-ftp=shared \
                --enable-intl=shared \
                --enable-json=shared \
                --enable-libxml \
                        --with-libxml-dir=/usr \
                --enable-pdo=shared \
                        --with-pdo-mysql=shared,mysqlnd \
                        --with-pdo-sqlite=shared,/usr \
                --enable-session=shared \
                --enable-shmop=shared \
                --enable-simplexml=shared \
                --enable-sockets=shared \
                --with-ldap=shared \
                        --with-ldap-sasl \
                --enable-mbstring=shared \
                --enable-mysqlnd=shared \
                --enable-opcache=shared \
                --enable-pcntl=shared \
                --enable-tokenizer=shared \
                --enable-xml=shared \
                --enable-xmlreader=shared \
                --enable-xmlwriter=shared \
                --enable-zip=shared \
                        --with-libzip=/usr \
                --with-pcre-regex=/usr \
                        --without-pcre-jit \
                --with-layout=GNU \
                --with-pic \
                --with-bz2=shared \
                --with-gettext=shared \
                --with-gmp=shared \
                --with-iconv=shared \
                --with-imap=shared \
                        --with-imap-ssl \
                --with-icu-dir=/usr \
                --with-password-argon2=shared \
                --with-sodium=shared \
                --with-sqlite3=shared,/usr \
                --with-curl=shared \
                --with-gd=shared,/usr \
                        --disable-gd-jis-conv \
                        --with-freetype-dir=/usr \
                        --with-jpeg-dir=/usr \
                        --with-png-dir=/usr \
                        --with-webp-dir=/usr \
                        --with-xpm-dir=/usr \
                --with-kerberos \
                --with-libedit \
                --with-mysqli=shared,mysqlnd \
                --with-openssl=shared \
                        --with-system-ciphers \
                --with-tidy=shared \
                --with-xmlrpc=shared \
                --with-xsl=shared \
                --with-zlib \
                        --with-zlib-dir=/usr \
                --with-config-file-path="${INSTALL_ROOT}${PHP_INI_DIR}" \
                --with-config-file-scan-dir="${INSTALL_ROOT}${PHP_INI_DIR}/conf.d" \
                --without-readline \
                ;
RUN make -j "$(nproc)" \
  ; find -type f -name '*.a' -delete \
  ;
RUN make install \
  ; DESTDIR='' INSTALL_ROOT='' make install \
  ; rm -rf \
         "${INSTALL_ROOT}/usr/share/man" \
         "${INSTALL_ROOT}/usr/include" \
         "${INSTALL_ROOT}/usr/lib/php/build" \
  ; find \
         "/usr/bin" \
         "/usr/sbin" \
         "${INSTALL_ROOT}/usr/bin" \
         "${INSTALL_ROOT}/usr/sbin" \
         -type f \
         -perm +0111 \
         -exec strip \
         --strip-all '{}' + || true

WORKDIR /usr/src/unit

RUN set -ex \
  ; git clone --no-checkout --jobs "$(nproc)" https://github.com/nginx/unit . \
  ; git checkout "${UNIT_VERSION}" \
  ; rm -rf .git
RUN ./configure \
                --group=app \
                --user=app \
                --prefix=/usr \
                --modules=/usr/lib/unit/modules \
                --pid=/tmp/unit.pid \
                --state=/var/lib/unit \
                --log=/var/log/unit.log \
                --control=[::]:8001 \
                ;
RUN ./configure php \
                --module=php72 \
                --config=/usr/bin/php-config \
                --lib-path=/usr/lib \
                ;
RUN make
RUN set -ex \
  ; make install \
  ; find \
         "${INSTALL_ROOT}/usr/bin" \
         "${INSTALL_ROOT}/usr/sbin" \
         -type f \
         -perm +0111 \
         -exec strip \
         --strip-all '{}' + || true

COPY docker/php.ini "${INSTALL_ROOT}/etc/php/php.ini"
COPY docker/extensions.ini "${INSTALL_ROOT}/etc/php/conf.d/extensions.ini"

# --- Base

FROM base

WORKDIR /app

COPY --from=dist /install /

USER app
EXPOSE 8001
ENTRYPOINT ["unitd", "--no-daemon"]
