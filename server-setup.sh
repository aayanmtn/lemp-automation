#!/bin/bash

# Exit on error
set -e

# Update system
apt-get update && apt-get upgrade -y

# Install required packages
apt-get install -y nginx mysql-server php-fpm php-mysql php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip

# Configure UFW firewall
ufw allow 'Nginx Full'
ufw allow OpenSSH
ufw --force enable

# Install Certbot for SSL
apt-get install -y certbot python3-certbot-nginx

# Configure MySQL secure installation
mysql_secure_installation <<EOF

y
strong_password_here
strong_password_here
y
y
y
y
EOF

# Create WordPress database and user
mysql -e "CREATE DATABASE wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
mysql -e "CREATE USER 'wordpressuser'@'localhost' IDENTIFIED BY 'strong_password_here';"
mysql -e "GRANT ALL ON wordpress.* TO 'wordpressuser'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Optimize MySQL
cat > /etc/mysql/conf.d/optimization.cnf <<EOL
[mysqld]
query_cache_size = 64M
query_cache_type = 1
max_connections = 100
key_buffer_size = 32M
innodb_buffer_pool_size = 256M
innodb_file_per_table = 1
EOL

# Configure PHP
sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 64M/' /etc/php/8.1/fpm/php.ini
sed -i 's/post_max_size = 8M/post_max_size = 64M/' /etc/php/8.1/fpm/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 256M/' /etc/php/8.1/fpm/php.ini

# Restart services
systemctl restart mysql
systemctl restart php8.1-fpm
systemctl restart nginx
