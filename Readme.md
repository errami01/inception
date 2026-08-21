*This project has been created as part of the 42 curriculum by aberrami.*

# Inception

# Description

Inception is a system administration project from the 42 curriculum focused on learning Docker, containerization, networking, persistent storage, service orchestration, and infrastructure design.

The goal of the project is to build a small web infrastructure composed of several independent Docker containers. Each service has its own Docker image and container, and the services communicate through a dedicated Docker network.

The mandatory infrastructure consists of three services:

- **NGINX** — the only public entrypoint, providing HTTPS with TLS.
- **WordPress + PHP-FPM** — the application layer serving the WordPress website.
- **MariaDB** — the database used by WordPress.

The architecture is:

```text
                         HTTPS :443
                             │
                             ▼
                    ┌─────────────────┐
                    │      NGINX      │
                    │  TLS 1.2 / 1.3 │
                    └────────┬────────┘
                             │
                         FastCGI
                             │
                             ▼
                    ┌─────────────────┐
                    │    WordPress    │
                    │    PHP-FPM      │
                    └────────┬────────┘
                             │
                         MariaDB
                             │
                             ▼
                    ┌─────────────────┐
                    │     MariaDB     │
                    └─────────────────┘

             ┌──────────────────────────────┐
             │     Docker Network           │
             │        inception             │
             └──────────────────────────────┘

             Persistent storage:
             ├── MariaDB data
             └── WordPress files
```
# Installation
## Prerequisites

The project is designed to run inside a Linux virtual machine as required by the 42 subject.

The environment should have:

- Linux
- Docker
- Docker Compose
- Make
- Git

Check Docker:
```bash
docker --version
```
Check Docker Compose:
```bash
docker compose version
```

## Configuration
Clone the repository:
```bash
git clone <repository-url>
cd inception
```
Configure:
```
srcs/.env
```
with the appropriate values.

The domain should follow the required format:
```
YOUR_LOGIN.42.fr
```

Configure /etc/hosts:
```bash
sudo nano /etc/hosts
```
Add:
```
127.0.0.1 YOUR_LOGIN.42.fr
```
Adjust the IP address if the virtual machine uses another local address.

## Usage
### Build and start the infrastructure
From the repository root:
```bash
make
```
or:
```bash
make up
```
The Makefile invokes Docker Compose and builds the project images.

### Check running containers
```bash
docker compose -f srcs/docker-compose.yml ps
```
or:
```
make ps
```
The mandatory infrastructure should contain:
```
nginx
wordpress
mariadb
```
### View logs
```bash
make logs
```
Individual services can also be inspected:
```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```
### Stop the infrastructure
```bash
make stop
```
This stops the containers without removing them.

### Stop and remove containers
```bash
make down
```
This removes the Compose containers while preserving persistent volumes unless the Makefile target explicitly removes them.

### Full cleanup
```bash
make fclean
```
This removes containers, networks, volumes, and project images according to the Makefile configuration.

Use this carefully because removing the persistent volumes deletes the stored WordPress and MariaDB data.
### Rebuild
```bash
make re
```
This performs a full cleanup followed by a complete rebuild and startup.

### Accessing WordPress
Once the containers are running, open:
```
https://YOUR_LOGIN.42.fr
```
The WordPress administration panel is available at:
```
https://YOUR_LOGIN.42.fr/wp-admin
```
The administrator credentials are defined through the project's local environment/secrets configuration.
## Container Lifecycle
The containers are configured to restart if they crash.

Each service runs its actual daemon as the main container process.

For example:
```
NGINX
  └── nginx

WordPress
  └── php-fpm

MariaDB
  └── mariadbd
```
The project avoids artificial container keep-alive techniques such as:
```
tail -f
sleep infinity
while true
```
This allows Docker to correctly monitor the actual service process.

Entrypoint scripts are used only for initialization and eventually replace themselves with the real service process using ```exec```.
# Technical Architecture
## Services:
### 1- NGINX
NGINX is the only public entrypoint into the infrastructure.

Responsibilities:

- Accept HTTPS connections.
- Listen on port 443 only.
- Support TLS 1.2 and TLS 1.3.
- Serve static WordPress files.
- Forward PHP requests to PHP-FPM.
- Terminate TLS connections.

NGINX does not contain PHP or MariaDB.

### 2- WordPress + PHP-FPM

The WordPress container contains:

- WordPress
- PHP
- PHP-FPM
- Required PHP extensions
- WP-CLI

Responsibilities:

- Run the WordPress application.
- Execute PHP through PHP-FPM.
- Connect to MariaDB.
- Persist the WordPress website files.

NGINX is deliberately not installed in this container.

### 3- MariaDB

The MariaDB container contains only the database service and its required dependencies.

Responsibilities:

- Store the WordPress database.
- Create the required database and users during first initialization.
- Persist database data.
- Accept database connections from the WordPress - container.

NGINX and WordPress are not installed in this container.

## Docker
Docker is used to package each service into its own isolated environment.

Instead of installing NGINX, PHP-FPM, WordPress, and MariaDB directly on the host system, each service is built into a separate Docker image and executed in its own container.

This provides:

- Isolation between services.
- Reproducible environments.
- Easier deployment.
- Independent service configuration.
- Explicit networking.
- Persistent storage through volumes.
- Easier lifecycle management.

Each service has its own Dockerfile, and the Dockerfiles are built through Docker Compose.

The base images use Debian rather than pre-built application images. The project does not use ready-made Docker images for the application services.

## Docker Compose
Docker Compose is used to define and orchestrate the complete infrastructure.

The Compose configuration defines:

- Services
- Builds
- Networks
- Volumes
- Environment variables
- Service dependencies
- Restart policies
- Exposed ports

The infrastructure can therefore be started with a single command through the Makefile.

## Project Structure
The repository follows the structure required by the project:
```txt
.
├── Makefile
├── README.md
├── .gitignore
├── secrets/
│
└── srcs/
    ├── .env
    ├── docker-compose.yml
    │
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        │
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        │
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

## Persistent Storage
Two persistent storages are used.

### 1- MariaDB volume

The MariaDB volume stores:

- Database tables
- WordPress database data
- MariaDB system data

The data persists when the MariaDB container is removed or recreated.

### 2- WordPress volume

The WordPress volume stores:

- WordPress core files
- Themes
- Plugins
- Media/uploads
- wp-config.php

The WordPress volume is shared between the WordPress and NGINX containers because both services need access to the website files.

Both persistent volumes are Docker named volumes and their host data is stored under:
```
/home/YOUR_LOGIN/data/
```
For example:
```
/home/YOUR_LOGIN/data/
├── mariadb/
└── wordpress/
```
The volume configuration is handled by Docker rather than directly bind-mounting host directories into the services.

## Docker Network
All mandatory services communicate through a dedicated Docker bridge network:
```
inception
```
The network allows containers to communicate using their Compose service names.

For example, WordPress connects to MariaDB using:
```
mariadb
```
rather than an IP address.

NGINX connects to PHP-FPM using:
```
wordpress:9000
```
This avoids hardcoding container IP addresses.

The project does not use:

- network: host
- Docker links
- links:

## HTTPS and TLS
NGINX is the only publicly accessible service.

The infrastructure exposes:
```
443
```
and does not expose port 80.

TLS is configured using TLS 1.2 and TLS 1.3.

The expected domain is:
```
YOUR_LOGIN.42.fr
```
The domain is configured locally to resolve to the IP address of the virtual machine.

For local development, the /etc/hosts file can contain:
```
127.0.0.1 YOUR_LOGIN.42.fr
```
The website is then accessible at:

```
https://YOUR_LOGIN.42.fr
```
Because the certificate is locally generated/self-signed, a browser may display a certificate warning during local development.

## Environment Variables and Secrets
The project uses environment variables for configuration.

The main environment configuration is stored in:
```
srcs/.env
```
Typical variables include:
```
DOMAIN_NAME=YOUR_LOGIN.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress_user

WP_TITLE=Inception
WP_ADMIN_USER=...
WP_ADMIN_EMAIL=...
WP_USER=...
WP_USER_EMAIL=...
```
Passwords and other confidential credentials must never be committed to the Git repository.

The .env file must therefore be excluded from Git when it contains sensitive values.

The repository may also use Docker secrets stored under:
```
secrets/
```
for sensitive credentials.

Example:
```
secrets/
├── db_password.txt
├── db_root_password.txt
└── credentials.txt
```
These files must remain local and must not be committed to the repository.