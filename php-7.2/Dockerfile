FROM alpine:3.10 AS base

ENV TZ "UTC"
RUN set -ex \
  # Create unprivileged user
  ; addgroup -g 1042 app                           \
  ; adduser -s /sbin/nologin -G app -u 1042 -D app \
  # Install depended packages
  ; apk add --no-cache \
            argon2-libs        \
            aspell-libs        \
            enchant            \
            icu-libs           \
            libbz2             \
            libcurl            \
            libcrypto1.1       \
            libgcc             \
            libintl            \
            libjpeg-turbo      \
            libpng             \
            libpq              \
            libsodium          \
            libssl1.1          \
            libstdc++          \
            # libstdc++6         \
            libwebp            \
            libxml2            \
            libxslt            \
            libzip             \
            nghttp2-libs       \
            openssl            \
            recode             \
            tidyhtml-libs      \
            tzdata             \
            zlib               \
            \
  # Create state directory for unit
  ; mkdir -p /var/lib/unit/certs   \
  ; chown -R app:app /var/lib/unit \
  ; chmod 0700 /var/lib/unit       \
  # Setup timezone
  ; ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
  ; echo $TZ > /etc/timezone
#
# --- Sources
#
FROM php:7.2-alpine AS sources

ENV UNIT_VERSION "1.13.0"

RUN docker-php-source extract
RUN apk add --no-cache --quiet \
            ca-certificates    \
            git                \
  ;
RUN git clone \
        --depth=1                        \
        --single-branch                  \
        --branch "${UNIT_VERSION}"       \
         "https://github.com/nginx/unit" \
         /usr/src/unit                   \
  ;
#
# --- Builder
#
FROM base AS builder

ENV PHP_INI_DIR "/etc/php"
ENV PHP_SCANDIR "/etc/php/conf.d"
ENV INSTALL_DIR "/install"

RUN mkdir -p \
              "${PHP_INI_DIR}" \
              "${PHP_SCANDIR}" \
              "${INSTALL_DIR}" \
  ;

COPY --from=sources /usr/src /usr/src

RUN apk add --no-cache --quiet \
            argon2-dev         \
            aspell-dev         \
            autoconf           \
            bison              \
            bzip2-dev          \
            ca-certificates    \
            coreutils          \
            curl-dev           \
            dpkg               \
            enchant-dev        \
            file               \
            g++                \
            gcc                \
            gd-dev             \
            gettext-dev        \
            git                \
            gmp-dev            \
            icu-dev            \
            imap-dev           \
            jpeg-dev           \
            krb5-dev           \
            lddtree            \
            libc-dev           \
            libedit-dev        \
            libical-dev        \
            libjpeg-turbo-dev  \
            libpng-dev         \
            libsodium-dev      \
            libwebp-dev        \
            libxml2-dev        \
            libxslt-dev        \
            libzip-dev         \
            make               \
            musl-dev           \
            openssl-dev        \
            pcre-dev           \
            pkgconf            \
            postgresql-dev     \
            re2c               \
            recode-dev         \
            tidyhtml-dev       \
            zlib-dev           \
  ;
#
# --- PHP Builder
#
FROM builder AS php-builder

WORKDIR /usr/src/php

ENV HIDE_WARN "-Wno-deprecated -Wno-deprecated-declarations"
ENV ADD_LFS   "-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV LDFLAGS   "-Wl,-O1 -Wl,--hash-style=gnu -pie"
ENV CPPFLAGS  "${HIDE_WARN} -fstack-protector-strong -fpic -fpie -O2 ${ADD_LFS}"
ENV HIDE_C_W  "-Wno-stringop-overflow -Wno-discarded-qualifiers -Wno-incompatible-pointer-types"
ENV CFLAGS    "${HIDE_C_W} ${CPPFLAGS}"

RUN ./configure \
                --enable-option-checking=fatal                      \
                \
                --build="x86_64-linux-musl"                         \
                --prefix=/usr                                       \
                --sysconfdir="${PHP_INI_DIR}"                       \
                --with-config-file-path="${PHP_INI_DIR}"            \
                --with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
                --localstatedir=/var                                \
                --with-layout=GNU                                   \
                --with-gnu-ld                                       \
                --with-pic                                          \
                \
                --disable-phpdbg                                    \
                --disable-short-tags                                \
                --disable-cgi                                       \
                \
                --without-pear                                      \
                --without-pdo-sqlite                                \
                --without-readline                                  \
                \
                --enable-embed=shared                               \
                --enable-dba=shared                                 \
                --enable-bcmath=shared                              \
                --enable-calendar=shared                            \
                --enable-ctype                                      \
                --enable-dom=shared                                 \
                --enable-exif=shared                                \
                --enable-ftp=shared                                 \
                --enable-intl=shared                                \
                --enable-json                                       \
                --enable-libxml                                     \
                --enable-opcache=shared                             \
                --enable-mbstring                                   \
                --enable-mysqlnd                                    \
                --enable-pcntl=shared                               \
                --enable-pdo=shared                                 \
                --enable-phar=shared                                \
                --enable-posix                                      \
                --enable-session                                    \
                --enable-shmop=shared                               \
                --enable-simplexml                                  \
                --enable-soap=shared                                \
                --enable-sockets=shared                             \
                --enable-sysvmsg                                    \
                --enable-sysvsem                                    \
                --enable-sysvshm                                    \
                --enable-tokenizer                                  \
                --enable-xml=shared                                 \
                --enable-xmlreader=shared                           \
                --enable-xmlwriter=shared                           \
                --enable-zip=shared                                 \
                \
                --with-bz2=shared                                   \
                --with-curl                                         \
                --with-enchant=/usr                                 \
                --with-gd=shared                                    \
                --with-gettext=shared                               \
                --with-iconv                                        \
                --with-icu-dir=/usr                                 \
                --with-jpeg-dir=/usr                                \
                --with-kerberos                                     \
                --with-libxml-dir=/usr                              \
                --with-libzip=/usr                                  \
                --with-openssl                                      \
                --with-password-argon2                              \
                --with-pcre-regex                                   \
                --with-pdo-mysql=shared,mysqlnd                     \
                --with-pdo-pgsql=shared                             \
                --with-pgsql=shared                                 \
                --with-png-dir=/usr                                 \
                --with-pspell=shared                                \
                --with-recode=shared                                \
                --with-sodium=/usr                                  \
                --with-system-ciphers                               \
                --with-tidy=shared                                  \
                --with-webp-dir=/usr                                \
                --with-xmlrpc=shared                                \
                --with-xsl=shared                                   \
                --with-zlib                                         \
  > /dev/null;

RUN make -j "$(nproc)" > /dev/null

ENV DESTDIR="${INSTALL_DIR}"
ENV INSTALL_ROOT="${INSTALL_DIR}"

RUN mkdir -p "${INSTALL_DIR}${PHP_SCANDIR}"
RUN cp php.ini-* "${INSTALL_DIR}${PHP_INI_DIR}"
RUN set -ex \
  ; make install \
  ; find \
         "${INSTALL_DIR}"   \
         -type f            \
         -perm +0111        \
         -exec strip        \
         --strip-all '{}' + \
         || true            \
  ; rm -rf "${INSTALL_DIR}/usr/share/man"
RUN scanelf \
            --needed         \
            --nobanner       \
            --format '%n#p'  \
            --recursive      \
            "${INSTALL_DIR}" \
    | tr ',' '\n'            \
    | sort -u
#
# --- Test PHP modules
#
FROM base AS test-php-modules

COPY --from=php-builder /install /

ENV PHP_EXT_DIR "/usr/lib/php/20170718"
ENV TARGET_INI  "/etc/php/conf.d/extensions.ini"

RUN set -eu \
  ; echo "zend_extension=$PHP_EXT_DIR/opcache.so" > "$TARGET_INI"      \
  ; for extension in $( ls "$PHP_EXT_DIR/"*.so | grep -v opcache ); do \
        echo "extension=$extension" >> "$TARGET_INI";                  \
    done

USER app

RUN cat "$TARGET_INI"
RUN php -m

#
# --- Unit Builder
#
FROM builder AS unit-builder

WORKDIR /usr/src/unit

COPY --from=php-builder /install /

RUN ./configure \
                --group=app                     \
                --user=app                      \
                --prefix=/usr                   \
                --modules=/usr/lib/unit/modules \
                --pid=/tmp/unit.pid             \
                --state=/var/lib/unit           \
                --log=/dev/stderr               \
                --control=[::]:8001             \
                --openssl                       \
  > /dev/null

RUN ./configure php \
                --module=php                    \
                --config=/usr/bin/php-config    \
                --lib-path=/usr/lib             \
  > /dev/null

RUN make -j "$(nproc)" > /dev/null

ENV DESTDIR="${INSTALL_DIR}"
ENV INSTALL_ROOT="${INSTALL_DIR}"

RUN set -ex \
  ; make install \
  ; find \
          "${INSTALL_DIR}"   \
          -type f            \
          -perm +0111        \
          -exec strip        \
          --strip-all '{}' + \
          || true            \
  ; rm -rf "${INSTALL_DIR}/usr/share/man"

#
# --- PHP Debug
#
FROM php-builder AS php-debug

ENV XDEBUG_VERSION="2.9.0"

WORKDIR /usr/src/php

ENV INSTALL_DIR=
ENV INSTALL_ROOT=
ENV DESTDIR=

ENV HIDE_WARN "-Wno-deprecated -Wno-deprecated-declarations"
ENV ADD_LFS   "-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV LDFLAGS   "-Wl,-O1 -Wl,--hash-style=gnu -pie"
ENV CPPFLAGS  "${HIDE_WARN} -fstack-protector-strong -fpic -fpie -O2 ${ADD_LFS}"
ENV HIDE_C_W  "-Wno-stringop-overflow -Wno-discarded-qualifiers -Wno-incompatible-pointer-types"
ENV CFLAGS    "${HIDE_C_W} ${CPPFLAGS}"

RUN ./configure \
                --enable-option-checking=fatal                      \
                \
                --build="x86_64-linux-musl"                         \
                --prefix=/usr                                       \
                --sysconfdir="${PHP_INI_DIR}"                       \
                --with-config-file-path="${PHP_INI_DIR}"            \
                --with-config-file-scan-dir="${PHP_INI_DIR}/conf.d" \
                --localstatedir=/var                                \
                --with-layout=GNU                                   \
                --with-gnu-ld                                       \
                --with-pic                                          \
                \
                --disable-short-tags                                \
                --disable-cgi                                       \
                \
                --enable-embed=shared                               \
                --enable-dba=shared                                 \
                --enable-bcmath=shared                              \
                --enable-calendar=shared                            \
                --enable-ctype                                      \
                --enable-dom=shared                                 \
                --enable-exif=shared                                \
                --enable-ftp=shared                                 \
                --enable-intl=shared                                \
                --enable-json                                       \
                --enable-libxml                                     \
                --enable-opcache=shared                             \
                --enable-mbstring                                   \
                --enable-mysqlnd                                    \
                --enable-pcntl=shared                               \
                --enable-pdo=shared                                 \
                --enable-phar=shared                                \
                --enable-phpdbg=shared                              \
                --enable-phpdbg-webhelper=shared                    \
                --enable-posix                                      \
                --enable-session                                    \
                --enable-shmop=shared                               \
                --enable-simplexml                                  \
                --enable-soap=shared                                \
                --enable-sockets=shared                             \
                --enable-sysvmsg                                    \
                --enable-sysvsem                                    \
                --enable-sysvshm                                    \
                --enable-tokenizer                                  \
                --enable-xml=shared                                 \
                --enable-xmlreader=shared                           \
                --enable-xmlwriter=shared                           \
                --enable-zip=shared                                 \
                \
                --with-bz2=shared                                   \
                --with-curl                                         \
                --with-enchant=/usr                                 \
                --with-gd=shared                                    \
                --with-gettext=shared                               \
                --with-iconv                                        \
                --with-icu-dir=/usr                                 \
                --with-jpeg-dir=/usr                                \
                --with-kerberos                                     \
                --with-libxml-dir=/usr                              \
                --with-libzip=/usr                                  \
                --with-openssl                                      \
                --with-password-argon2                              \
                --with-pcre-regex                                   \
                --with-pdo-mysql=shared,mysqlnd                     \
                --with-pdo-pgsql=shared                             \
                --with-pear=shared                                  \
                --with-pgsql=shared                                 \
                --with-png-dir=/usr                                 \
                --with-pspell=shared                                \
                --with-recode=shared                                \
                --with-sodium=/usr                                  \
                --with-system-ciphers                               \
                --with-tidy=shared                                  \
                --with-webp-dir=/usr                                \
                --with-xmlrpc=shared                                \
                --with-xsl=shared                                   \
                --with-zlib                                         \
                \
                --without-pdo-sqlite                                \
  > /dev/null;

RUN make -j "$(nproc)" > /dev/null

RUN mkdir -p "${PHP_SCANDIR}"
RUN cp php.ini-* "${PHP_INI_DIR}"
RUN make install

RUN git clone https://github.com/xdebug/xdebug.git /usr/src/xdebug

WORKDIR /usr/src/xdebug

RUN git checkout "$XDEBUG_VERSION"
RUN set -ex \
  ; phpize \
  ; ./configure --enable-xdebug > /dev/null \
  ; make clean
RUN make -j "$(nproc)" > /dev/null
RUN make install

WORKDIR /usr/src/unit

ENV HIDE_WARN=
ENV ADD_LFS=
ENV LDFLAGS=
ENV CPPFLAGS=
ENV HIDE_C_W=
ENV CFLAGS=

RUN ./configure \
                --group=app                     \
                --user=app                      \
                --prefix=/usr                   \
                --modules=/usr/lib/unit/modules \
                --pid=unit.pid                  \
                --log=unit.log                  \
                --state=/var/lib/unit           \
                --control=[::]:8001             \
                --openssl                       \
  > /dev/null

RUN ./configure php \
                --module=php                    \
                --config=/usr/bin/php-config    \
                --lib-path=/usr/lib             \
  > /dev/null

RUN make -j "$(nproc)" > /dev/null
RUN make install

RUN rm -rf /install

WORKDIR /app

EXPOSE 8001

#
# --- Test
#
FROM php-debug AS test-php-debug-modules

ENV PHP_EXT_DIR "/usr/lib/php/20170718"
ENV TARGET_INI  "/etc/php/conf.d/extensions.ini"

RUN set -eu \
  ; echo "zend_extension=$PHP_EXT_DIR/opcache.so" > "$TARGET_INI"      \
  ; echo "zend_extension=$PHP_EXT_DIR/xdebug.so" >> "$TARGET_INI"      \
  ; for extension in $( ls "$PHP_EXT_DIR/"*.so | grep -v opcache | grep -v xdebug); do \
        echo "extension=$extension" >> "$TARGET_INI";                  \
    done

USER app

RUN cat "$TARGET_INI"
RUN php -m

#
# --- Base
#
FROM base

WORKDIR /app

COPY --from=php-builder  /install /
COPY --from=unit-builder /install /

EXPOSE 8001
