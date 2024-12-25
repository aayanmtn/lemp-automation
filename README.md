# WordPress DevOps Deployment Solution

## Overview
This repository contains an automated deployment setup for a WordPress website using the LEMP stack (Linux, Nginx, MySQL, PHP) and GitHub Actions for CI/CD. The solution includes server provisioning scripts, configuration files, and deployment workflows.

## Repository Structure
```
.
├── .github/
│   └── workflows/
│       └── deploy.yml
├── scripts/
│   ├── server-setup.sh
│   └── wordpress-setup.sh
├── configs/
│   ├── nginx/
│   │   ├── nginx.conf
│   │   └── wordpress.conf
│   └── php/
│       └── php.ini
├── .env.example
└── README.md
```

## Server Setup Instructions

### Prerequisites
- Ubuntu 22.04 VPS instance
- Domain name pointed to your server's IP
- GitHub account with repository access
- SSH key pair for deployment

### Initial Server Setup

1. SSH into your server and run the server setup script:
```bash
chmod +x scripts/server-setup.sh
./scripts/server-setup.sh
```

2. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your configurations
```

3. Setup WordPress:
```bash
chmod +x scripts/wordpress-setup.sh
./scripts/wordpress-setup.sh
```

### GitHub Actions Configuration

1. Add the following secrets to your GitHub repository:
- `SERVER_HOST`: Your server's IP address
- `SERVER_USERNAME`: SSH username
- `SSH_PRIVATE_KEY`: SSH private key for deployment
- `WORDPRESS_DB_PASSWORD`: MySQL root password

2. Push your code to trigger the deployment workflow.

## Security Considerations
- All sensitive data is stored in GitHub Secrets
- UFW firewall configured to allow only necessary ports
- SSL/TLS certificates auto-renewed
- WordPress salts automatically generated
- File permissions properly set
- Regular security updates enabled

## Performance Optimizations
- Nginx FastCGI caching enabled
- Gzip compression configured
- PHP-FPM process manager optimized
- MySQL query cache configured
- WordPress object caching implemented

## Monitoring and Maintenance
- Server health monitoring setup
- Automated backups configured
- Log rotation enabled
- Performance monitoring tools installed
