ARG ALPINE_TAG=3.12.1
FROM alpine:$ALPINE_TAG as config-alpine

ARG BRANCH=v0.0.0

RUN apk add --no-cache tzdata

RUN cp -v /usr/share/zoneinfo/America/New_York /etc/localtime
RUN echo "America/New_York" > /etc/timezone

RUN apk add --no-cache --update git

RUN git config --global advice.detachedHead false
RUN git clone --branch=2.4 --depth=1 https://github.com/CachetHQ/Docker.git
RUN git clone --branch=2.4 --depth=1 https://github.com/CachetHQ/Cachet.git

FROM nginx:1.17.8-alpine

COPY --from=config-alpine /etc/localtime /etc/localtime
COPY --from=config-alpine /etc/timezone  /etc/timezone

ENV COMPOSER_VERSION 1.9.0

RUN apk add --no-cache --update mysql-client php7 php7-apcu \
    php7-bcmath php7-ctype php7-curl php7-dom php7-fileinfo php7-fpm \
    php7-gd php7-iconv php7-intl php7-json php7-mbstring php7-mcrypt \
    php7-mysqlnd php7-opcache php7-openssl php7-pdo php7-pdo_mysql \
    php7-pdo_pgsql php7-pdo_sqlite php7-phar php7-posix php7-redis \
    php7-session php7-simplexml php7-soap php7-sqlite3 php7-tokenizer \
    php7-xml php7-xmlwriter php7-zip php7-zlib postfix postgresql \
    postgresql-client sqlite sudo wget sqlite git curl bash grep \
    supervisor
    
# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    ln -sf /dev/stdout /var/log/php7/error.log && \
    ln -sf /dev/stderr /var/log/php7/error.log

RUN adduser -S -s /bin/bash -u 1001 -G root www-data

RUN echo "www-data    ALL=(ALL:ALL)    NOPASSWD:SETENV:    /usr/sbin/postfix" >> /etc/sudoers

RUN touch /var/run/nginx.pid && \
    chown -R www-data:root /var/run/nginx.pid

RUN chown -R www-data:root /etc/php7/php-fpm.d

RUN mkdir -p /var/www/html && \
    mkdir -p /usr/share/nginx/cache && \
    mkdir -p /var/cache/nginx && \
    mkdir -p /var/lib/nginx && \
    chown -R www-data:root /var/www /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx/

# Install composer
RUN wget https://getcomposer.org/installer -O /tmp/composer-setup.php && \
    wget https://composer.github.io/installer.sig -O /tmp/composer-setup.sig && \
    php -r "if (hash('SHA384', file_get_contents('/tmp/composer-setup.php')) !== trim(file_get_contents('/tmp/composer-setup.sig'))) { unlink('/tmp/composer-setup.php'); echo 'Invalid installer' . PHP_EOL; exit(1); }" && \
    php /tmp/composer-setup.php --version=$COMPOSER_VERSION --install-dir=bin && \
    php -r "unlink('/tmp/composer-setup.php');"

COPY --from=config-alpine /Cachet /var/www/html

COPY --from=config-alpine /Docker/conf/php-fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY --from=config-alpine /Docker/conf/nginx.conf /etc/nginx/nginx.conf
COPY --from=config-alpine /Docker/conf/nginx-site.conf /etc/nginx/conf.d/default.conf
COPY --from=config-alpine /Docker/conf/supervisord.conf /etc/supervisor/supervisord.conf
COPY --from=config-alpine /Docker/entrypoint.sh /sbin/entrypoint.sh

# COPY --from=config-alpine /Docker/conf/.env.docker /var/www/html/.env
# COPY cachet.env /etc/cachet/cachet.env
# COPY cachet.env /var/www/html/.env

RUN touch /var/www/html/.env

# COPY cachet.sqlite /opt/cachet-data/cachet.sql
RUN mkdir -pv /opt/cachet-data/
RUN touch /opt/cachet-data/cachet.sql

RUN ln -s /opt/cachet-data/cachet.sql /var/www/html/database/database.sqlite
# RUN ln -s /etc/cachet/cachet.env /var/www/html/.env

RUN chown -R www-data:root /opt/cachet-data/cachet.sql
RUN chown -R www-data:root /var/www/html

WORKDIR /var/www/html/

RUN chmod g+rwx /var/run/nginx.pid && \
    chmod -R g+rw /var/www /usr/share/nginx/cache /var/cache/nginx /var/lib/nginx/ /etc/php7/php-fpm.d storage

ENV DB_DRIVER sqlite
# ENV DB_HOST ./database.sqlite

USER 1001

RUN php /bin/composer.phar global require "hirak/prestissimo:^0.3"
RUN php /bin/composer.phar install -o
RUN rm -rf bootstrap/cache/*

# RUN touch ./database.sqlite

RUN php artisan key:generate
# php artisan config:clear
RUN php artisan config:cache

EXPOSE 8000
CMD ["/sbin/entrypoint.sh"]
