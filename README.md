# WordPress DevOps Deployment Solution

## Overview
This repository contains an automated deployment setup for a WordPress website using the LEMP stack (Linux, Nginx, MySQL, PHP) and GitHub Actions for CI/CD. The solution includes server provisioning scripts, configuration files, and deployment workflows.

## Repository Structure
```
.
├── .github/
│   └── workflows/
│       └── main.yml
├── wordpress/
│   ├── 
│   └── 
├── deploy.sh/
│
│
│
│       
└── README.md
```

# WordPress LEMP Stack Deployment on EC2

This repository automates the deployment of a LEMP (Linux, Nginx, MySQL/MariaDB, PHP) stack for WordPress on an EC2 instance using GitHub Actions. The workflow includes steps for installing and configuring necessary components such as Nginx, PHP, Redis, Varnish, Fail2Ban, ModSecurity, and Let's Encrypt SSL.

## Workflow Overview

The GitHub Actions workflow triggers whenever changes are pushed to the `main` branch. It automates the following tasks:

1. **Nginx Installation**: Installs and configures Nginx as the web server.
2. **PHP Installation**: Installs the necessary PHP extensions and PHP-FPM.
3. **Redis Installation**: Installs Redis for caching.
4. **Varnish Installation**: Configures Varnish Cache in front of Nginx.
5. **Fail2Ban Setup**: Configures Fail2Ban to secure the server.
6. **ModSecurity Setup**: Installs and configures ModSecurity for extra security on Nginx.
7. **Let's Encrypt SSL Setup**: Automatically installs and renews Let's Encrypt SSL certificates for secure HTTPS connections.
8. **Firewall Setup**: Configures UFW (Uncomplicated Firewall) to allow only necessary ports.
9. **WordPress Installation**: Installs and configures WordPress on the EC2 instance.

## Required Secrets

For the GitHub Actions workflow to work correctly, you will need to set the following secrets in your GitHub repository:

### 1. **`SSH_PRIVATE_KEY`**
   - **Type**: SSH private key
   - **Description**: This is the private SSH key that will be used to access your EC2 instance. You must add the corresponding public key to your EC2 instance's `~/.ssh/authorized_keys` file to allow SSH access.

### 2. **`REMOTE_USER`**
   - **Type**: String
   - **Description**: The username for SSH access to the EC2 instance (e.g., `ubuntu`, `ec2-user`, etc.).

### 3. **`REMOTE_HOST`**
   - **Type**: String
   - **Description**: The public IP address or DNS hostname of your EC2 instance (e.g., `ec2-xx-xx-xx-xx.us-west-1.compute.amazonaws.com` or `203.0.113.0`).

### 4. **`DB_NAME`**
   - **Type**: String
   - **Description**: The name of the database to be created for WordPress (e.g., `wordpress_db`).

### 5. **`DB_USER`**
   - **Type**: String
   - **Description**: The username for the WordPress database (e.g., `wp_user`).

### 6. **`DB_PASSWORD`**
   - **Type**: String
   - **Description**: The password for the WordPress database user (e.g., `securepassword123`).

### 7. **`SERVER_NAME`**
   - **Type**: String
   - **Description**: The fully qualified domain name (FQDN) of your server (e.g., `example.com` or `www.example.com`). This is used for SSL certificate generation with Let's Encrypt.

### 8. **`EMAIL`**
   - **Type**: String
   - **Description**: Your email address used for Let's Encrypt registration and notifications (e.g., `your-email@example.com`).

### 9. **`REDIS_PASSWORD`**
   - **Type**: String (Optional)
   - **Description**: The password to secure the Redis server if you are enabling password authentication for Redis. This should be set to a secure value.

### 10. **`AWS_ACCESS_KEY_ID`**
   - **Type**: String
   - **Description**: The AWS Access Key ID for authenticating API requests to Amazon Web Services (if your EC2 instance is not publicly accessible, or if you're interacting with other AWS services).

### 11. **`AWS_SECRET_ACCESS_KEY`**
   - **Type**: String
   - **Description**: The AWS Secret Access Key that corresponds to the above Access Key ID for secure access to AWS services.

---

## Setup Instructions

1. **Generate SSH Keys**: Generate an SSH key pair if you haven't already, and add the public key to the EC2 instance.

   ```bash
   ssh-keygen -t rsa -b 2048 -f my-ec2-key

