#!/usr/bin/env bash

# Use single quotes instead of double quotes to make it work with special-character passwords
PASSWORD='12345678'
PROJECTFOLDER='myproject'

# create project folder
sudo mkdir "/var/www/html/${PROJECTFOLDER}"

# update / upgrade
sudo apt-get update
sudo apt-get -y upgrade

# install nginx and php 5.5
sudo apt-get install -y nginx
sudo apt-get install -y php5-fpm php5-common php5-mcrypt php5-curl php5-cli php5-mysql php5-gd php-pear php-apc

 
# install mysql and give password to installer
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
sudo apt-get install -y mysql-server


# Configure Nginx
if [ ! -f /etc/nginx/sites-available/magento ]; then
    sudo touch /etc/nginx/sites-available/magento
fi

if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm /etc/nginx/sites-enabled/default
fi

if [ ! -f /etc/nginx/sites-enabled/magento ]; then
    sudo ln -s /etc/nginx/sites-available/magento /etc/nginx/sites-enabled/magento
fi

# Configure host
cat << 'EOF' > /etc/nginx/sites-available/magento
server {
	listen 80;

	root /var/www/html/myproject;

	index index.php index.html index.htm;

	server_name magento.local;

	# Place PHP error logs in the Magento log folder
	set $php_log /var/www/html/myproject/var/log/php_errors.log;

	# Replaces Apache rewrite rules
	location / {
		try_files $uri $uri/ @handler;
	}

	# Protect sensitive folders
	location /app/                { deny all; }
	location /includes/           { deny all; }
	location /lib/                { deny all; }
	location /media/downloadable/ { deny all; }
	location /pkginfo/            { deny all; }
	location /report/config.xml   { deny all; }
	location /var/                { deny all; }

	# Protect dotfiles (htaccess, svn, etc.)
	location /. { return 404; }

	location @handler {
		rewrite / /index.php;
	}

	# Remove trailing slashes from PHP files
	location ~ .php/ {
		rewrite ^(.*.php)/ $1 last;
	}

	# Pass PHP to a the PHP-FPM backend
	location ~ \.php$ {
		# Fix timeouts when installing Magento via web interface
		fastcgi_send_timeout 1800;
		fastcgi_read_timeout 1800;
		fastcgi_connect_timeout 1800;

		try_files $uri =404;
		fastcgi_pass unix:/var/run/php5-fpm.sock;
		fastcgi_index index.php;
		#fastcgi_param MAGE_IS_DEVELOPER_MODE on; # Turn on developer mode
		#fastcgi_param MAGE_RUN_CODE $mage_run_code;
		#fastcgi_param MAGE_RUN_TYPE $mage_run_type;
		fastcgi_param PHP_VALUE error_log=$php_log;
		include fastcgi_params;       
	}
}
EOF

#enable the mcrypt extension
sudo php5enmod mcrypt
# Restart servers
sudo service nginx restart
sudo service php5-fpm restart



# install git
sudo apt-get -y install git

# install Composer
curl -s https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer