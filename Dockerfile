FROM centos:7

# Install base packages.
RUN yum -y install epel-release yum-plugin-ovl deltarpm && \
    yum -y update && \
    yum -y install sudo ssh curl less vim-minimal dnsutils openssl

# Download confd.
ENV CONFD_VERSION 0.11.0
RUN curl -L "https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-$CONFD_VERSION-linux-amd64" > /usr/bin/confd && \
    chmod +x /usr/bin/confd
ENV CONFD_OPTS '--backend=env --onetime'

ENV RUBY_VERSION 2.3
ENV RUBY ruby23

RUN yum -y install \
      centos-release-scl-rh \
      https://www.softwarecollections.org/en/scls/remi/php56more/epel-7-x86_64/download/remi-php56more-epel-7-x86_64.noarch.rpm \
      https://www.softwarecollections.org/en/scls/rhscl/$RUBY/epel-7-x86_64/download/rhscl-$RUBY-epel-7-x86_64.noarch.rpm \
      https://www.softwarecollections.org/en/scls/rhscl/v8314/epel-7-x86_64/download/rhscl-v8314-epel-7-x86_64.noarch.rpm && \
    yum -y update

RUN yum -y install \
      bzip2 \
      gcc-c++ \
      git \
      httpd-tools \
      jq \
      make \
      mariadb \
      nmap-ncat \
      patch \
      postgresql \
      $RUBY \
      $RUBY-rubygems \
      $RUBY-ruby-devel \
      sendmail \
      unzip \
      # Necessary for drush
      which \
      # Necessary library for phantomjs per https://github.com/ariya/phantomjs/issues/10904
      fontconfig \
      # Install PHP
      rh-php56 \
      rh-php56-php-gd \
      rh-php56-php-xml \
      rh-php56-php-pdo \
      rh-php56-php-mysql \
      rh-php56-php-mbstring \
      rh-php56-php-fpm \
      rh-php56-php-opcache \
      rh-php56-php-pecl-memcache \
      rh-php56-php-pecl-xdebug \
      more-php56-php-mcrypt \
      more-php56-php-pecl-xhprof

# Ensure $RUBY binaries are in path
ENV PATH /root/.composer/vendor/bin:/opt/rh/$RUBY/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Ensure PHP Binaries are in path
RUN ln -sfv /opt/rh/rh-php56/root/usr/bin/* /usr/bin/ && \
    ln -sfv /opt/rh/rh-php56/root/usr/sbin/* /usr/sbin/

# Enable other $RUBY SCL config
ENV LD_LIBRARY_PATH /opt/rh/$RUBY/root/usr/lib64
ENV PKG_CONFIG_PATH /opt/rh/$RUBY/root/usr/lib64/pkgconfig

# Ensure $HOME is set
ENV HOME /root

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/bin/composer
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER 1

# Install Drush
RUN composer global require drush/drush:8.x
RUN composer global require drupal/console:@stable
RUN curl https://drupalconsole.com/installer -L -o /usr/bin/drupal && chmod +x /usr/bin/drupal
RUN drupal self-update
RUN drupal init -n

# Install Prestissimo for composer performance
RUN composer global require "hirak/prestissimo:^0.3"

# Update composer libraries
RUN composer global update

# Install nvm, supported node versions, and default cli modules.
ENV NVM_DIR $HOME/.nvm
ENV NODE_VERSION 4
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash

# Node 4.x (LTS)
RUN source $NVM_DIR/nvm.sh \
      && nvm install 4 \
      && npm install -g bower grunt-cli gulp-cli yo
# Node 5.x (stable)
RUN source $NVM_DIR/nvm.sh \
      && nvm install 5 \
      && npm install -g bower grunt-cli gulp-cli yo
# Node 6.x (LTS)
RUN source $NVM_DIR/nvm.sh \
      && nvm install 6 \
      && npm install -g bower grunt-cli gulp-cli yo
# Set the default version which can be overridden by ENV.
RUN source $NVM_DIR/nvm.sh \
      && nvm alias default $NODE_VERSION
RUN source $NVM_DIR/nvm.sh && nvm cache clear

COPY root /

# Install Drush commands
RUN drush pm-download -yv registry_rebuild-7.x --destination=/etc/drush/commands

# Run the s6-based init.
ENTRYPOINT ["/init"]

# Set up a standard volume for logs.
VOLUME ["/var/log/services"]

CMD [ "/versions.sh" ]
