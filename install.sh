#!/bin/bash
db_root_password="462470"

export DEBIAN_FRONTEND=noninteractive

sudo apt update
sudo apt-get data
sudo apt-get install -y tzdata
sudo ln -fs /usr/share/zoneinfo/Asia/Taipei /etc/localtime
sudo dpkg-reconfigure --frontend noninteractive tzdata

sudo apt-get install -y nano nginx mariadb-server mariadb-client php-fpm php-mysql php-cli

##Run mysql_secure_installation
# Make sure that NOBODY can access the server without a password
sudo mysql -uroot <<_EOF_
UPDATE mysql.user SET Password=PASSWORD('${db_root_password}') WHERE User='root';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
use mysql;
update user set plugin='' where User='root';
FLUSH PRIVILEGES;
_EOF_

#Configure PHP.
sudo cp /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini.bak
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
#Configure phpinfo Page
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php
#Configure nginx default
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
sudo cp ~/default /etc/nginx/sites-available/default
#Install Configure Composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
HASH="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer

#Install Configure phpMyAdmin
export DEBIAN_FRONTEND=noninteractive
sudo apt-get -yq install phpmyadmin
sudo cp /usr/share/phpmyadmin/config.sample.inc.php /etc/phpmyadmin/config.inc.php
sudo dpkg-reconfigure --frontend=noninteractive phpmyadmin
sudo mv /usr/share/phpmyadmin/ /usr/share/phpMyAdmin/

#Finish Restart Service
sudo nginx -t
sudo systemctl restart php7.0-fpm
sudo systemctl restart nginx
sudo systemctl restart mysql
