#!/bin/bash

set -e

# Function to check if a package is installed
function check_package {
  if ! dpkg -l | grep -q "$1"; then
    echo "$1 is not installed. Installing..."
    sudo apt-get install -y "$1"
  else
    echo "$1 is already installed."
  fi
}

# Function to check if a service is running
function check_service {
  if ! systemctl is-active --quiet "$1"; then
    echo "$1 is not running. Starting it..."
    sudo systemctl start "$1"
  else
    echo "$1 is running."
  fi
}

# Function to generate a Salt key (password)
function generate_salt_key {
  # Create a random Salt key (16 characters)
  SALT_KEY=$(openssl rand -base64 16)
  echo "Generated Salt key: $SALT_KEY"
  
  # Store the Salt key in a file
  echo "$SALT_KEY" > /etc/secret/salt_key.txt
  echo "Salt key saved to /etc/secret/salt_key.txt"
}

# Function to replace the default Salt key in the configuration file
function replace_salt_key_in_file {
  local file=$1
  local default_key=$2
  local salt_key=$3
  
  if grep -q "$default_key" "$file"; then
    echo "Replacing default Salt key in $file with the new Salt key..."
    sudo sed -i "s/$default_key/$salt_key/" "$file"
    echo "Salt key replaced successfully."
  else
    echo "No default key found in $file. Adding the new Salt key..."
    echo "$salt_key" | sudo tee -a "$file" > /dev/null
    echo "Salt key added successfully."
  fi
}

# Step 1: Update and upgrade the system
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Step 2: Generate and store Salt key (this will replace the default password/key)
generate_salt_key

# Step 3: Install and configure PHP and required extensions for WordPress
echo "Installing PHP and required extensions..."

# Get the current PHP version installed on the system (defaulting to PHP 8.1 if not found)
PHP_VERSION=$(php -v | head -n 1 | awk '{print $2}' | cut -d. -f1,2)  # Example: 7.4 or 8.1
if [ -z "$PHP_VERSION" ]; then
  PHP_VERSION="8.1"
fi

# Install PHP-FPM and required extensions dynamically based on the current PHP version
check_package "php${PHP_VERSION}-fpm"
check_package "php${PHP_VERSION}-mysql"
check_package "php${PHP_VERSION}-cli"
check_package "php${PHP_VERSION}-curl"
check_package "php${PHP_VERSION}-xml"
check_package "php${PHP_VERSION}-mbstring"
check_package "php${PHP_VERSION}-json"
check_package "php${PHP_VERSION}-zip"
check_package "php${PHP_VERSION}-gd"
check_package "php${PHP_VERSION}-imagick"
check_package "php${PHP_VERSION}-redis"

# Step 4: Install and configure Nginx for WordPress
echo "Installing and configuring Nginx for WordPress..."

# Install Nginx if not already installed
check_package nginx

# Create a basic Nginx configuration for WordPress
NGINX_CONF="/etc/nginx/sites-available/wordpress"
sudo bash -c "cat > $NGINX_CONF" <<EOL
server {
    listen 80;
    server_name ${SERVER_NAME};  # Set your server name here (e.g., example.com)

    root /var/www/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    access_log /var/log/nginx/wordpress_access.log;
    error_log /var/log/nginx/wordpress_error.log;
}
EOL

# Enable the site by creating a symbolic link
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/

# Test the Nginx configuration
sudo nginx -t

# Restart Nginx to apply the changes
sudo systemctl restart nginx

# Step 5: Install and configure Redis (with Salt key for security)
check_package redis-server

# Configure Redis to use Salt key for password protection
if ! systemctl is-active --quiet redis-server; then
  echo "Configuring Redis with Salt key..."
  SALT_KEY=$(cat /etc/secret/salt_key.txt)  # Read the Salt key from the file
  sudo sed -i "s/^# requirepass .*/requirepass $SALT_KEY/" /etc/redis/redis.conf
  sudo systemctl restart redis-server
else
  echo "Redis is already installed and running."
fi

# Step 6: Replace default Salt key in wp-config.php if needed
WP_CONFIG_FILE="/var/www/wordpress/wp-config.php"

# Replace the default Salt keys in wp-config.php
echo "Replacing default WordPress Salt keys in wp-config.php..."
DEFAULT_SALT="put your unique phrase here"
replace_salt_key_in_file "$WP_CONFIG_FILE" "$DEFAULT_SALT" "$(cat /etc/secret/salt_key.txt)"

# Step 7: Install Fail2Ban if not installed
check_package fail2ban

# Configure Fail2Ban for Nginx if not already configured
if ! test -f "/etc/fail2ban/jail.d/nginx-http-auth.conf"; then
  echo "Configuring Fail2Ban..."
  sudo bash -c 'cat > /etc/fail2ban/jail.d/nginx-http-auth.conf' <<EOL
[nginx-http-auth]
enabled = true
port    = http,https
filter  = nginx-http-auth
logpath = /var/log/nginx/error.log
maxretry = 3
EOL
  sudo systemctl restart fail2ban
else
  echo "Fail2Ban is already configured."
fi

# Step 8: Install and configure ModSecurity for Nginx if not installed
check_package libnginx-mod-security

# Enable ModSecurity module in Nginx if not already configured
if ! test -f "/etc/nginx/modsec/main.conf"; then
  echo "Configuring ModSecurity..."
  sudo bash -c 'cat > /etc/nginx/modsec/main.conf' <<EOL
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecRule ARGS|ARGS_NAMES|REQUEST_HEADERS|XML:/* "@rx wp-login.php" \
  "phase:2,deny,status:403,msg:'WordPress login attempt blocked'"
EOL
  sudo sed -i 's|#include /etc/nginx/modsec/*.conf;|include /etc/nginx/modsec/main.conf;|' /etc/nginx/nginx.conf
  sudo nginx -t && sudo systemctl reload nginx
else
  echo "ModSecurity is already configured."
fi

# Step 9: Install and configure Let's Encrypt SSL if not already installed
check_package certbot
check_package python3-certbot-nginx

# Install SSL certificate only if not already issued
if ! certbot certificates | grep -q "${SERVER_NAME}"; then
  echo "Installing Let's Encrypt SSL certificates..."
  sudo certbot --nginx -d ${SERVER_NAME} --non-interactive --agree-tos -m ${EMAIL}
  
  # Set up auto-renewal for Let's Encrypt if not already set up
  if ! systemctl is-enabled --quiet certbot.timer; then
    echo "Setting up automatic SSL certificate renewal..."
    sudo systemctl enable certbot.timer
    sudo systemctl start certbot.timer
  else
    echo "Automatic SSL certificate renewal is already set up."
  fi
else
  echo "Let's Encrypt SSL certificates are already installed."
fi

# Step 10: Install and configure Varnish if not already configured
if ! systemctl is-active --quiet varnish; then
  echo "Configuring Varnish Cache..."

  # Varnish configuration file for WordPress
  VARNISH_CONF="/etc/varnish/default.vcl"
  sudo bash -c "cat > $VARNISH_CONF" <<EOL
vcl 4.0;
import std;

backend default {
    .host = "127.0.0.1";
    .port =
