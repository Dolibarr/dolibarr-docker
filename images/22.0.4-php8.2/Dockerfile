ARG ARCH=

# ============================================================
# BUILDER STAGE — compile PHP extensions & fetch Dolibarr
# ============================================================
FROM ${ARCH}php:8.2-apache-bookworm AS builder

RUN apt-get update -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        libc-client-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libkrb5-dev \
        libldap2-dev \
        libldap-common \
        libpng-dev \
        libpq-dev \
        libxml2-dev \
        libzip-dev \
        libtidy-dev \
        curl \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) calendar intl mysqli pdo_mysql gd soap zip opcache tidy \
    && docker-php-ext-configure pgsql -with-pgsql \
    && docker-php-ext-install pdo_pgsql pgsql \
    && docker-php-ext-configure ldap --with-libdir=lib/$(gcc -dumpmachine)/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && rm -rf /var/lib/apt/lists/*

# Download Dolibarr
ENV DOLI_VERSION=develop

RUN curl -fLSs https://github.com/Dolibarr/dolibarr/archive/${DOLI_VERSION}.tar.gz | \
    tar -C /tmp -xz && \
    cp -r /tmp/dolibarr-${DOLI_VERSION}/htdocs/. /var/www/html/ && \
    ln -s /var/www/html /var/www/htdocs && \
    cp -r /tmp/dolibarr-${DOLI_VERSION}/scripts /var/www/ && \
    rm -rf /tmp/dolibarr-${DOLI_VERSION} && \
    mkdir -p /var/www/documents && \
    mkdir -p /var/www/html/custom && \
    chown -R www-data:www-data /var/www

# ============================================================
# RUNTIME STAGE — only what's needed to run Dolibarr
# ============================================================
FROM ${ARCH}php:8.2-apache-bookworm

# Credit/Initial maintainer: Garcia MICHEL <garcia@soamichel.fr>
# Modified according to the GPL license by developers of the Dolibarr community:
# 2024 Alois Micard
# 2024 Laurent Destailleur
# 2025 Renato de Castro Ferreira

LABEL maintainer="The Dolibarr foundation <contact@dolibarr.org>"

# ---- All original environment variables preserved ----
ENV DOLI_VERSION=22.0.4
ENV DOLI_VERSION_FOR_INIT_DEMO=22.0
ENV DOLI_INSTALL_AUTO=1
ENV DOLI_PROD=1
ENV DOLI_DB_TYPE=mysqli
ENV DOLI_DB_HOST=mysql
ENV DOLI_DB_HOST_PORT=3306
ENV DOLI_DB_NAME=dolidb
ENV DOLI_DB_SSL=false
<<<<<<< Updated upstream
ENV DOLI_URL_ROOT=''
=======
ENV DOLI_URL_ROOT='http://localhost'
>>>>>>> Stashed changes
ENV DOLI_AUTH=dolibarr
ENV DOLI_LDAP_HOST=127.0.0.1
ENV DOLI_LDAP_PORT=389
ENV DOLI_LDAP_VERSION=3
ENV DOLI_LDAP_SERVER_TYPE=openldap
ENV DOLI_LDAP_LOGIN_ATTRIBUTE=uid
ENV DOLI_LDAP_DN='ou=users,dc=my-domain,dc=com'
ENV DOLI_LDAP_FILTER=''
ENV DOLI_LDAP_BIND_DN=''
ENV DOLI_LDAP_BIND_PASS=''
ENV DOLI_LDAP_DEBUG=false
ENV DOLI_CRON=0
ENV WWW_USER_ID=33
ENV WWW_GROUP_ID=33
ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV PHP_INI_MEMORY_LIMIT=256M
ENV PHP_INI_UPLOAD_MAX_FILESIZE=20M
ENV PHP_INI_POST_MAX_SIZE=22M
ENV PHP_INI_ALLOW_URL_FOPEN=0

# ---- Install ONLY runtime shared libraries (no -dev, no compilers) ----
RUN apt-get update -y \
    && apt-get dist-upgrade -y \
    && apt-get install -y --no-install-recommends \
        libc-client2007e \
        libfreetype6 \
        libjpeg62-turbo \
        libkrb5-3 \
        libldap-2.5-0 \
        libldap-common \
        libpng16-16 \
        libpq5 \
        libxml2 \
        libzip4 \
        libtidy5deb1 \
        default-mysql-client \
        postgresql-client \
        cron \
    && apt-get remove -y --purge build-essential g++ gcc make binutils cpp \
    && apt-get remove -y --purge dpkg-dev libc6-dev libc-dev-bin libstdc++-12-dev libgcc-12-dev linux-libc-dev \
    # 2. Remove Unnecessary Utilities (Safe to remove)
    && apt-get remove -y --purge re2c autoconf m4 xz-utils \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

# ---- Copy compiled PHP extensions + configs from builder ----
COPY --from=builder /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=builder /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/

# ---- Production php.ini + hardening (same as upstream) ----
RUN mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini \
    && sed -i 's/expose_php = On/expose_php = Off/g' ${PHP_INI_DIR}/php.ini

# ---- Apache hardening (same as upstream) ----
RUN a2disconf serve-cgi-bin \
    && a2dismod status \
    && a2dismod -f alias \
    && a2dismod -f autoindex \
    && a2enmod rewrite \
    && sed -i \
        -e 's/^\(ServerSignature On\)$/#\1/g' \
        -e 's/^#\(ServerSignature Off\)$/\1/g' \
        -e 's/^\(ServerTokens\) OS$/\1 Prod/g' \
        /etc/apache2/conf-available/security.conf

# ---- Copy Dolibarr application from builder ----
COPY --from=builder --chown=www-data:www-data /var/www/html /var/www/html
COPY --from=builder --chown=www-data:www-data /var/www/scripts /var/www/scripts
COPY --from=builder --chown=www-data:www-data /var/www/documents /var/www/documents
RUN ln -s /var/www/html /var/www/htdocs

EXPOSE 80

VOLUME /var/www/documents
VOLUME /var/www/html/custom
