FROM php:7.2-fpm

ENV BIN_PATH=bin
ENV NGINX_CONFIG_SRC_PATH=nginx
ENV PHP_CONFIG_SRC_PATH=php
ENV S6_CONFIG_SRC_PATH=s6
ENV WEB_USER=www-data
ENV PHANTOMJS phantomjs-2.1.1-linux-x86_64
ENV INVOICENINJA_VERSION 4.5.9
ENV LOG errorlog
ENV SELF_UPDATER_SOURCE ''
ENV PHANTOMJS_BIN_PATH /usr/local/bin/phantomjs

### S6 OVERLAY ###
COPY $BIN_PATH/s6-overlay-amd64.tar.gz /tmp/s6-overlay-amd64.tar.gz
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /
ADD $S6_CONFIG_SRC_PATH/services /etc/services.d/
ADD $S6_CONFIG_SRC_PATH/init /etc/cont-init.d/
ADD $S6_CONFIG_SRC_PATH/scripts /usr/bin/


#####
# SYSTEM REQUIREMENT
#####
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        zlib1g-dev git libgmp-dev unzip nginx-full \
        libfreetype6-dev libjpeg62-turbo-dev libpng-dev \
        build-essential chrpath libssl-dev libxft-dev \
        libfreetype6 libfontconfig1 libfontconfig1-dev \
    && ln -s /usr/include/x86_64-linux-gnu/gmp.h /usr/local/include/ \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure gmp \
    && docker-php-ext-install iconv mbstring pdo pdo_mysql zip gd gmp opcache \
    && curl -o ${PHANTOMJS}.tar.bz2 -SL https://bitbucket.org/ariya/phantomjs/downloads/${PHANTOMJS}.tar.bz2 \
    && tar xvjf ${PHANTOMJS}.tar.bz2 \
    && rm ${PHANTOMJS}.tar.bz2 \
    && mv ${PHANTOMJS} /usr/local/share \
    && ln -sf /usr/local/share/${PHANTOMJS}/bin/phantomjs /usr/local/bin \
	&& curl -o ninja.zip -SL https://download.invoiceninja.com/ninja-v${INVOICENINJA_VERSION}.zip \
    && unzip ninja.zip -d /var/www/ \
    && rm ninja.zip \
    && mv /var/www/ninja /var/www/app  \
    && mv /var/www/app/storage /var/www/app/docker-backup-storage  \
    && mv /var/www/app/public /var/www/app/docker-backup-public  \
    && mkdir -p /var/www/app/public/logo /var/www/app/storage \
    && touch /var/www/app/.env \
    && chmod -R 755 /var/www/app/storage  \
    && chown -R www-data:www-data /var/www/app/storage /var/www/app/bootstrap /var/www/app/public/logo /var/www/app/.env /var/www/app/docker-backup-storage /var/www/app/docker-backup-public\
    && rm -rf /var/www/app/docs /var/www/app/tests /var/www/ninja \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
} > /usr/local/etc/php/conf.d/opcache-recommended.ini


COPY $NGINX_CONFIG_SRC_PATH/nginx.conf /etc/nginx/nginx.conf
COPY $NGINX_CONFIG_SRC_PATH/vhost.conf /etc/nginx/customers.d/vhost.conf
COPY $NGINX_CONFIG_SRC_PATH/fastcgi.conf /etc/nginx/conf/fastcgi.conf
COPY $NGINX_CONFIG_SRC_PATH/spider.conf /etc/nginx/conf/spider.conf
COPY $NGINX_CONFIG_SRC_PATH/referer.conf /etc/nginx/conf/referer.conf
COPY $NGINX_CONFIG_SRC_PATH/upstream.conf /etc/nginx/conf/upstream.conf
COPY $NGINX_CONFIG_SRC_PATH/default.conf /etc/nginx/conf.d/default.conf
COPY $NGINX_CONFIG_SRC_PATH/status.conf /etc/nginx/conf.d/status.conf
COPY $NGINX_CONFIG_SRC_PATH/php-fpm.conf /usr/local/etc/php-fpm.conf
COPY $NGINX_CONFIG_SRC_PATH/www.conf /etc/php7/php-fpm.d/craft.conf
COPY $PHP_CONFIG_SRC_PATH/php.ini /usr/local/etc/php/php.ini


WORKDIR /var/www/app


ENTRYPOINT [ "/init" ]
