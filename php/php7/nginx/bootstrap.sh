#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='myproject'

# create project folder
sudo mkdir "/var/www/html/${PROJECTFOLDER}"

# update / upgrade
Update () {
    sudo apt-get update
    sudo apt-get upgrade
}
Update

#Install tools and helpers
sudo apt-get install -y python-software-properties vim htop curl git npm

# INSTALL NGINX 
sudo apt-get install -y nginx

#configure NGINX


#install php
sudo apt-get install -y php-fpm php-common php-mbstring php-xmlrpc php-soap php-gd php-xml php-intl php-mysqlnd php-cli php-mcrypt php-ldap php-zip php-curl




# Configure Nginx
if [ ! -f /etc/nginx/sites-available/vagrant ]; then
    touch /etc/nginx/sites-available/vagrant
fi

if [ -f /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
fi

if [ ! -f /etc/nginx/sites-enabled/vagrant ]; then
    ln -s /etc/nginx/sites-available/vagrant /etc/nginx/sites-enabled/vagrant
fi

# Configure host
cat << 'EOF' > /etc/nginx/sites-available/vagrant
upstream fastcgi_backend {
         server  unix:/run/php/php7.1-fpm.sock;
}
server {
    listen 80;
    listen [::]:80;
	root /var/www/html/${PROJECTFOLDER};
    index  index.php index.html index.htm;

    set $MAGE_ROOT /var/www/html/${PROJECTFOLDER};
    set $MAGE_MODE developer;
    include /var/www/html/${PROJECTFOLDER}/nginx.conf.sample;
}
EOF
# Restart servers
service nginx restart
service php7.1-fpm restart



# INSTALL MARIADB and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get install -y  mariadb-server mariadb-client
sudo chmod 777 /var/run/mysqld/mysqld.sock

Update


# install git
sudo apt-get -y install git

# install Composer
curl -s https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

