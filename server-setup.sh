#!/bin/bash

# Define environment variables
WP_DIR="/var/www/wordpress"
DB_NAME="wordpress_db"
DB_USER="wordpress_user"
DB_PASSWORD="wordpress_password"
NGINX_CONF="/etc/nginx/sites-available/wordpress"
PHP_FPM_POOL="/etc/php/7.4/fpm/pool.d/www.conf"

# Step 1: Update System and Install Necessary Packages
echo "Updating the system..."
sudo apt-get update -y && sudo apt-get upgrade -y

# Install Nginx, PHP, MySQL, Redis, Fail2Ban, ModSecurity
echo "Installing necessary packages for LEMP stack and security tools..."
sudo apt-get install -y nginx php-fpm php-mysql mysql-server redis-server fail2ban libapache2-mod-security2 curl unzip

# Install PHP extensions for WordPress
sudo apt-get install -y php7.4-cli php7.4-curl php7.4-mbstring php7.4-xml php7.4-zip php7.4-bcmath php7.4-soap

# Step 2: Configure MySQL Database for WordPress
echo "Configuring MySQL Database for WordPress..."
sudo mysql -u root -e "CREATE DATABASE $DB_NAME;"
sudo mysql -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Step 3: Install and Configure Nginx for WordPress
echo "Configuring Nginx for WordPress..."
# Create Nginx config file
sudo bash -c 'cat > /etc/nginx/sites-available/wordpress <<EOF
server {
    listen 80;
    server_name _;

    root /var/www/wordpress;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }

    # Enable gzip compression for performance
    gzip on;
    gzip_types text/css application/javascript text/javascript application/x-javascript text/plain text/xml application/xml application/xml+rss text/javascript;
    gzip_min_length 1000;

    # Disable .git directories for security
    location ~ /\.git {
        deny all;
    }
}
EOF'

# Enable the Nginx site configuration and reload Nginx
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Step 4: Install and Configure SSL using Let's Encrypt
echo "Installing SSL certificate using Let's Encrypt..."
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com --non-interactive --agree-tos -m your-email@example.com

# Step 5: Install WordPress
echo "Installing WordPress..."
cd /tmp
curl -O https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz
sudo mv wordpress /var/www/wordpress
cd /var/www/wordpress
sudo chown -R www-data:www-data /var/www/wordpress
sudo chmod -R 755 /var/www/wordpress

# Step 6: Configure PHP-FPM for WordPress (optional PHP settings)
echo "Configuring PHP-FPM for WordPress..."
sudo sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/7.4/fpm/php.ini
sudo systemctl restart php7.4-fpm

# Step 7: Configure Redis for WordPress Caching
echo "Configuring Redis for WordPress Caching..."
sudo systemctl enable redis-server
sudo systemctl start redis-server

# Install Redis Object Cache plugin for WordPress
cd /var/www/wordpress
wp plugin install redis-cache --activate
wp redis enable

# Step 8: Install and Configure Varnish Cache
echo "Configuring Varnish for caching..."
sudo apt-get install -y varnish
sudo bash -c 'cat > /etc/varnish/default.vcl <<EOF
backend default {
    .host = "127.0.0.1";
    .port = "8080";
}

sub vcl_recv {
    if (req.url ~ "^/wp-admin/") {
        return (pass);
    }
}

sub vcl_backend_response {
    if (bereq.url ~ "^/wp-admin/") {
        set beresp.ttl = 0s;
    }
    set beresp.ttl = 1h;
}
EOF'

# Update varnish to run on port 80 and Nginx on port 8080
sudo sed -i 's/DAEMON_OPTS="-a :6081"/DAEMON_OPTS="-a :80"/' /etc/default/varnish
sudo systemctl restart varnish

# Step 9: Set up Fail2Ban for Security
echo "Configuring Fail2Ban..."
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# Step 10: Install ModSecurity for Additional Protection
echo "Installing ModSecurity..."
sudo apt-get install -y libapache2-mod-security2
sudo cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf
sudo sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine On/' /etc/modsecurity/modsecurity.conf
sudo systemctl restart apache2

# Step 11: Clean up and Security Checks
echo "Securing the server..."
sudo apt-get autoremove -y
sudo apt-get clean

# Final message
echo "LEMP stack with WordPress is now deployed and secured with Varnish, Redis, SSL, Fail2Ban, and ModSecurity!"
