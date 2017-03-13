FROM centos:7

# Install base packages.
RUN yum -y install epel-release centos-release-scl yum-plugin-ovl deltarpm && \
    yum -y update && \
    yum -y install sudo ssh curl less vim-minimal dnsutils openssl

RUN yum-config-manager --enable rhel-server-rhscl-7-rpms

ENV RUBY_VERSION 2.3
ENV RUBY ruby23

# Download confd.
ENV CONFD_VERSION 0.11.0
RUN curl -L "https://github.com/kelseyhightower/confd/releases/download/v$CONFD_VERSION/confd-$CONFD_VERSION-linux-amd64" > /usr/bin/confd && \
    chmod +x /usr/bin/confd
ENV CONFD_OPTS '--backend=env --onetime'

RUN yum -y install \
      https://rpms.remirepo.net/enterprise/remi-release-7.rpm \
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
      php70 \
      php70-php-gd \
      php70-php-xml \
      php70-php-pdo \
      php70-php-mysql \
      php70-php-mysqlnd \
      php70-php-mbstring \
      php70-php-fpm \
      php70-php-opcache \
      php70-php-pecl-memcache \
      php70-php-pecl-xdebug \
      php70-php-mcrypt \
      # There is no PHP 7 support for XHProf yet.
      # php70-php-pecl-xhprof \
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
      pv

RUN echo "Ensure $RUBY binaries are in path"
ENV PATH /root/.composer/vendor/bin:/opt/rh/$RUBY/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Ensure PHP binaries are in path
RUN ln -sfv /opt/remi/php70/root/usr/bin/* /usr/bin/ && \
    ln -sfv /opt/remi/php70/root/usr/sbin/* /usr/sbin/

RUN echo "Enable other $RUBY SCL config"
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

# Install Drupal Console / Laucher
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
# Node g.x (stable)
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
