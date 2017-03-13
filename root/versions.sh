#!/bin/sh

# Setup nvm to provide access to node commands
source $NVM_DIR/nvm.sh

echo ''
echo 'Node.js version:'
node --version
echo ''
echo 'npm version:'
npm --version
echo ''
echo 'Bower version:'
bower --version
echo ''
echo 'Grunt version:'
grunt --version
echo ''
echo 'Yeoman version:'
yo --version
echo ''
echo 'Ruby version:'
ruby --version
echo ''
echo 'Bundler version:'
bundle --version
echo ''
echo 'PHP version:'
php --version
echo ''
echo 'Composer version:'
composer --version
echo ''
echo 'Drush version:'
drush --version
echo ''
echo 'Drupal Console version:'
drupal --version
