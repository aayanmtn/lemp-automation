#!/bin/bash

# Exit on error
set -e

echo "Starting the deployment..."

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Step 1: Check if Nginx is installed, if not install it
echo "Checking if Nginx is installed..."
if ! command -v nginx &> /dev/null; then
  echo "Nginx not found. Installing Nginx..."
  sudo apt-get install -y nginx
else
  echo "Nginx is already installed."
fi

# Step 2: Check if MariaDB is installed, if not install it
echo "Checking if MariaDB is installed..."
if ! command -v mysql &> /dev/null; then
  echo "MariaDB not found. Installing MariaDB..."
  sudo apt-get install -y mariadb-server mariadb-client
else
  echo "MariaDB is already installed."
fi

# Step 3: Start and enable Nginx
echo "Starting and enabling Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

# Step 4: Start and enable MariaDB
echo "Starting and enabling MariaDB..."
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Step 5: Secure MariaDB (Optional - add a simple security setup)
echo "Securing MariaDB installation..."
sudo mysql_secure_installation

# Step 6: Check the status of Nginx and MariaDB
echo "Checking the status of Nginx..."
sudo systemctl status nginx --no-pager

echo "Checking the status of MariaDB..."
sudo systemctl status mariadb --no-pager

# Step 7: Final message
echo "LEMP stack (MariaDB and Nginx) has been installed and started successfully."
