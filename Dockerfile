FROM php:7.2-apache

# install the PHP extensions we need
RUN set -ex; \
	\
	savedAptMark="$(apt-mark showmanual)"; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
		libjpeg-dev \
		libpng-dev \
	; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install gd mysqli opcache; \
	\
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	\
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# Install addon things
RUN apt-get update && apt-get install -y \
	libjpeg-dev \
	libpng-dev \
#	libpng12-dev \
#	zlibc \
#	zlib1g \
	zlib1g-dev \
  mysql-client \
  wget \
  unzip \
	nano \
	sudo \
	less \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-install gd mysqli zip opcache

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# PHP custom upload settings
RUN { \
#  		echo 'file_uploads=On'; \
  		echo 'upload_max_filesize=10M'; \
#  		echo 'memory_limit=64M'; \
  		echo 'post_max_size=10M'; \
      echo 'max_execution_time = 600'; \
  	} > /usr/local/etc/php/conf.d/upload.ini

RUN a2enmod rewrite expires

VOLUME /var/www/html

ENV WORDPRESS_VERSION 4.9.5
ENV WORDPRESS_SHA1 6992f19163e21720b5693bed71ffe1ab17a4533a

RUN set -ex; \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress

# Custom scripts
# ADD vars.sh /vars.sh
# ADD ./entrypoint.sh /entrypoint.sh
ADD ./plugins.sh /plugins.sh
RUN chmod +x /plugins.sh # /entrypoint.sh /vars.sh

##############################################################################################
# WORDPRESS Config
##############################################################################################
# ADD ./wordpress/wp-config.php /var/www/html/wp-config.php
# chown wp-config.php to root
# RUN chown root:root /var/www/html/wp-config.php

##############################################################################################
# WORDPRESS Plugins Setup
##############################################################################################
RUN mkdir /plugins

# Add Plugin Lists
ADD ./wordpress/plugins/ /plugins

# Execute each on its own for better caching support
RUN /plugins.sh /plugins/base
RUN /plugins.sh /plugins/security

# Delete Plugins script and folder
RUN rm /plugins.sh && rm /plugins -r

# ADD Local Plugins
# ADD ./plugins/snapshot /var/www/html/wp-content/plugins/snapshot
ADD ./plugins/snapshot /usr/src/wordpress/wp-content/plugins/snapshot

##############################################################################################
# WORDPRESS Themes Setup
##############################################################################################
# ADD ./themes/my-theme /var/www/html/wp-content/themes/my-theme

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Cleanup
# RUN rm /plugins.sh && rm /plugins -r # Delete Plugins script and folder
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
