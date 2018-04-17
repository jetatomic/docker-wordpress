FROM wordpress:latest

# Install things
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

# PHP upload settings
RUN { \
#  		echo 'file_uploads=On'; \
  		echo 'upload_max_filesize=10M'; \
#  		echo 'memory_limit=64M'; \
  		echo 'post_max_size=10M'; \
      echo 'max_execution_time = 600';
  	} > /usr/local/etc/php/conf.d/upload.ini

# Recommended PHP.ini settings
# https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# add custom scripts
#	ADD vars.sh /vars.sh
#	ADD entrypoint.sh /entrypoint.sh
	ADD plugins.sh /plugins.sh
	RUN chmod +x /plugins.sh # /entrypoint.sh /vars.sh

# WORDPRESS Plugins Setup

RUN mkdir /plugins

# Add All Plugin Files
ADD ./wordpress/plugins/ /plugins

# Execute independently for better caching support
RUN /plugins.sh /plugins/base
RUN /plugins.sh /plugins/security

# Add Custom plugins
ADD ./plugins/snapshot /var/www/html/wp-content/plugins/snapshot

# WORDPRESS Themes Setup

# ADD ./themes/my-theme /var/www/html/wp-content/themes/my-theme

# Cleanup
RUN rm /plugins.sh && rm /plugins -r # Delete Plugins script and folder
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
