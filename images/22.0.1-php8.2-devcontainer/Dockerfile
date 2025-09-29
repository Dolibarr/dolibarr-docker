# Dolibarr Development Docker Image
# Based on the official Dolibarr 22.0.1-php8.2 image with development tools
# Extends: https://github.com/Dolibarr/dolibarr-docker/tree/main/images/22.0.1-php8.2

ARG ARCH=

# Use a PHP image
FROM ${ARCH}php:8.2-apache-bookworm AS base

# Credit/Initial maintainer: Garcia MICHEL <garcia@soamichel.fr>
# Modified according to the GPL license by developers of the Dolibarr community:
# 2024 Alois Micard
# 2024 Laurent Destailleur  
# 2025 Renato de Castro Ferreira
# 2025 Florian HÖDL <florian@hoedl.co>
# Development extensions by Dolibarr community
LABEL maintainer="The Dolibarr foundation <contact@dolibarr.org>"
LABEL description="Dolibarr Development Environment with VS Code DevContainer support"

ENV DOLI_VERSION=22.0.1
ENV DOLI_VERSION_FOR_INIT_DEMO=22.0
ENV DOLI_INSTALL_AUTO=0
ENV DOLI_PROD=0

ENV DOLI_DB_TYPE=mysqli
ENV DOLI_DB_HOST=db
ENV DOLI_DB_HOST_PORT=3306
ENV DOLI_DB_NAME=dolibarr
ENV DOLI_DB_SSL=false

ENV DOLI_URL_ROOT='http://localhost:8080'

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

ENV WWW_USER_ID=1000
ENV WWW_GROUP_ID=1000

# Development-specific PHP settings
ENV PHP_INI_DATE_TIMEZONE='UTC'
ENV PHP_INI_MEMORY_LIMIT=512M
ENV PHP_INI_UPLOAD_MAX_FILESIZE=100M
ENV PHP_INI_POST_MAX_SIZE=120M
ENV PHP_INI_ALLOW_URL_FOPEN=1

# Apache security settings
RUN sed -i \
  -e 's/^\(ServerSignature On\)$/#\1/g' \
  -e 's/^#\(ServerSignature Off\)$/\1/g' \
  -e 's/^\(ServerTokens\) OS$/\1 Prod/g' \
  /etc/apache2/conf-available/security.conf

# Install system dependencies (same as production)
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
        default-mysql-client \
        mariadb-client \
        postgresql-client \
        vim \
        nano \
        cron \
    && apt-get autoremove -y

# Install development tools including sudo
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        git \
        unzip \
        wget \
        curl \
        less \
        bash-completion \
        zip \
        htop \
        procps \
        net-tools \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Configure sudo for www-data user
RUN echo "www-data ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install PHP extensions (same as production)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) calendar intl mysqli pdo_mysql gd soap zip opcache tidy \
    && docker-php-ext-configure pgsql -with-pgsql \
    && docker-php-ext-install pdo_pgsql pgsql \
    && docker-php-ext-configure ldap --with-libdir=lib/$(gcc -dumpmachine)/ \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap

# Install Composer first
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# PHP configuration - setup base configuration before installing Xdebug
RUN mv ${PHP_INI_DIR}/php.ini-production ${PHP_INI_DIR}/php.ini \
    && sed -i 's/expose_php = On/expose_php = Off/g' ${PHP_INI_DIR}/php.ini

# Install Xdebug for development (after base PHP config)
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug

# Xdebug configuration for VS Code
RUN echo "[xdebug]" > ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "zend_extension=xdebug.so" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.mode=debug,coverage,develop" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.log=/var/log/xdebug.log" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=VSCODE" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.discover_client_host=1" >> ${PHP_INI_DIR}/conf.d/docker-php-ext-xdebug.ini

# Development PHP settings
RUN echo "# Development PHP settings" > ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "display_errors = On" >> ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "display_startup_errors = On" >> ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "error_reporting = E_ALL & ~E_DEPRECATED & ~E_STRICT" >> ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "log_errors = On" >> ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "html_errors = On" >> ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "opcache.enable = 0" >> ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "opcache.validate_timestamps = 1" >> ${PHP_INI_DIR}/conf.d/development.ini \
    && echo "opcache.revalidate_freq = 0" >> ${PHP_INI_DIR}/conf.d/development.ini

# Install PHP development tools globally - Fixed dependency conflicts
RUN composer global require \
        phpunit/phpunit:^10.0 \
        squizlabs/php_codesniffer:^3.7 \
        phpstan/phpstan:^1.10 \
        friendsofphp/php-cs-fixer:^3.0 \
        phpmd/phpmd:^2.13 \
    && echo 'export PATH="$PATH:/root/.composer/vendor/bin"' >> /root/.bashrc

# Create symlinks for easy access to dev tools
RUN ln -s /root/.composer/vendor/bin/phpunit /usr/local/bin/phpunit \
    && ln -s /root/.composer/vendor/bin/phpcs /usr/local/bin/phpcs \
    && ln -s /root/.composer/vendor/bin/phpcbf /usr/local/bin/phpcbf \
    && ln -s /root/.composer/vendor/bin/phpstan /usr/local/bin/phpstan \
    && ln -s /root/.composer/vendor/bin/php-cs-fixer /usr/local/bin/php-cs-fixer \
    && ln -s /root/.composer/vendor/bin/phpmd /usr/local/bin/phpmd

# Disable useless Apache modules to provide safe defaults
RUN a2disconf serve-cgi-bin \
    && a2dismod status \
    && a2dismod -f alias \
    && a2dismod -f autoindex

# Enable Apache rewrite module
RUN a2enmod rewrite

# Get Dolibarr (same as production but allow write for development)
RUN curl -fLSs https://github.com/Dolibarr/dolibarr/archive/${DOLI_VERSION}.tar.gz |\
    tar -C /tmp -xz && \
    cp -r /tmp/dolibarr-${DOLI_VERSION}/htdocs/* /var/www/html/ && \
    cp -r /tmp/dolibarr-${DOLI_VERSION}/scripts /var/www/ && \
    rm -rf /tmp/* && \
    mkdir -p /var/www/documents && \
    mkdir -p /var/www/html/custom && \
    mkdir -p /var/log && \
    touch /var/log/xdebug.log && \
    touch /var/log/php_errors.log && \
    chown -R www-data:www-data /var/www && \
    chown www-data:www-data /var/log/xdebug.log && \
    chown www-data:www-data /var/log/php_errors.log && \
    chmod -R u+w /var/www/html

# FIXED: Configure Apache to serve from the correct directory
RUN echo '<VirtualHost *:80>' > /etc/apache2/sites-available/000-default.conf && \
    echo '    DocumentRoot /var/www/html/htdocs' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    <Directory /var/www/html/htdocs>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        Options -Indexes +FollowSymLinks' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        AllowOverride All' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        Require all granted' >> /etc/apache2/sites-available/000-default.conf && \
    echo '        DirectoryIndex index.php index.html' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    </Directory>' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    ErrorLog ${APACHE_LOG_DIR}/error.log' >> /etc/apache2/sites-available/000-default.conf && \
    echo '    CustomLog ${APACHE_LOG_DIR}/access.log combined' >> /etc/apache2/sites-available/000-default.conf && \
    echo '</VirtualHost>' >> /etc/apache2/sites-available/000-default.conf

# Create directories that VS Code will need with proper permissions
RUN mkdir -p /var/www/.vscode-server /var/www/.vscode-remote \
    && chown -R www-data:www-data /var/www/.vscode-server /var/www/.vscode-remote \
    && chmod -R 755 /var/www/.vscode-server /var/www/.vscode-remote

# Copy development scripts and configuration
COPY scripts/ /usr/local/bin/dev-scripts/
COPY config/ /usr/local/etc/dolibarr-dev/

# Create development helper script
COPY dolibarr-dev-improved.sh /usr/local/bin/dolibarr-dev
RUN chmod +x /usr/local/bin/dolibarr-dev

# Development environment variables
ENV DOLI_DEV_MODE=1
ENV PHP_IDE_CONFIG="serverName=dolibarr-docker"
ENV XDEBUG_CONFIG="client_host=host.docker.internal client_port=9003 idekey=VSCODE"

EXPOSE 80
VOLUME /var/www/documents
VOLUME /var/www/html/custom

COPY docker-init.php /var/www/scripts/
COPY docker-run.sh /usr/local/bin/
ENTRYPOINT ["docker-run.sh"]

CMD ["apache2-foreground"]