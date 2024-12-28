#!/bin/bash

# Variables
DB_NAME="wordpress"
DB_USER="wordpress_user"
DB_PASSWORD="wordpress_password"
DB_HOST="localhost"
WP_DIR="/var/www/html/wordpress"
NGINX_CONF="/etc/nginx/sites-available/wordpress"
NGINX_CONF_LINK="/etc/nginx/sites-enabled/wordpress"
MYSQL_ROOT_PASSWORD="root_password"
PHP_VERSION="8.3"  # Modify this if you need a different PHP version
REPO_URL="https://github.com/aayanmtn/lemp-automation.git"  # Replace with your repo URL
REPO_BRANCH="main"  # Replace with your branch name (e.g., 'main' or 'master')
REPO_LOCAL_DIR="/tmp/"  # Local directory where the repo will be cloned

# Update the system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "Installing NGINX, MySQL, PHP, and dependencies..."
sudo apt install -y nginx mysql-server php$PHP_VERSION-fpm php$PHP_VERSION-mysql php$PHP_VERSION-cli php$PHP_VERSION-curl php$PHP_VERSION-xml php$PHP_VERSION-mbstring php$PHP_VERSION-zip curl unzip git

# Start and enable services
echo "Starting and enabling NGINX and MySQL..."
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mysql
sudo systemctl enable mysql

# Secure MySQL installation
echo "Securing MySQL installation..."
sudo mysql_secure_installation <<EOF

Y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
Y
Y
Y
Y
EOF

# Create WordPress database and user
echo "Creating WordPress database and user..."
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE $DB_NAME;"
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';"
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST';"
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

# Clone the repository if it's not already cloned
if [ ! -d "$REPO_LOCAL_DIR" ]; then
  echo "Cloning the repository from $REPO_URL..."
  git clone -b $REPO_BRANCH $REPO_URL $REPO_LOCAL_DIR
else
  echo "Repository already cloned, pulling the latest changes..."
  cd $REPO_LOCAL_DIR && git pull origin $REPO_BRANCH
fi

# Copy the 'wordpress' folder from the repo to the web directory
echo "Copying the 'wordpress' folder from the repo to the web directory..."
sudo cp -r $REPO_LOCAL_DIR/lemp-automation/wordpress $WP_DIR

# Set the correct permissions for WordPress files
echo "Setting the correct permissions for WordPress..."
sudo chown -R www-data:www-data $WP_DIR
sudo chmod -R 755 $WP_DIR

# Create wp-config.php
echo "Creating wp-config.php..."
cd $WP_DIR
cp wp-config-sample.php wp-config.php

# Configure wp-config.php with database details
sudo sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sudo sed -i "s/username_here/$DB_USER/" wp-config.php
sudo sed -i "s/password_here/$DB_PASSWORD/" wp-config.php

# Nginx configuration for WordPress
echo "Configuring NGINX for WordPress..."
sudo bash -c "cat > $NGINX_CONF <<EOF
server {
    listen 80;
    server_name himsec.sytes.net;  # Change this to your domain or IP address

    root $WP_DIR;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php$PHP_VERSION-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF"

# Enable the Nginx configuration by linking to sites-enabled
echo "Enabling NGINX configuration..."
sudo ln -s $NGINX_CONF $NGINX_CONF_LINK

# Test Nginx configuration for syntax errors
echo "Testing NGINX configuration..."
sudo nginx -t

# Restart Nginx to apply changes
echo "Restarting NGINX..."
sudo systemctl restart nginx

# Restart PHP-FPM to apply changes
echo "Restarting PHP-FPM..."
sudo systemctl restart php$PHP_VERSION-fpm

# Final steps
echo "LEMP stack installed and configured for WordPress!"
echo "You can now visit your website at http://your_domain.com or IP address."
echo "Complete the WordPress installation by visiting the URL in your browser."

# Clean up
echo "Cleaning up temporary files..."
rm -rf /tmp/your-repo
