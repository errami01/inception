# Inception — User Documentation

This document explains how to use and administer the Inception infrastructure after it has been installed.

The project provides a small WordPress website infrastructure composed of three services:

- **NGINX** — HTTPS entrypoint and web server.
- **WordPress + PHP-FPM** — website and PHP application.
- **MariaDB** — database used by WordPress.

The services run in separate Docker containers and communicate through a private Docker network.

---

# 1. Services Provided

## NGINX

NGINX is the entrypoint to the website.

It:

- Accepts HTTPS connections on port `443`.
- Handles TLS encryption.
- Serves static WordPress files.
- Sends PHP requests to PHP-FPM.

Users should access the website through NGINX rather than connecting directly to WordPress or MariaDB.

---

## WordPress

WordPress is the website application.

It:

- Provides the public website.
- Provides the WordPress administration panel.
- Stores uploaded media, themes, plugins, and website files.
- Uses PHP-FPM to execute PHP code.
- Connects to MariaDB for database operations.

---

## MariaDB

MariaDB is the database service.

It stores WordPress information such as:

- Posts
- Pages
- Users
- Settings
- Comments
- Plugin data
- Theme configuration

MariaDB is not directly accessible from the Internet. It communicates with WordPress through the private Docker network.

---

# 2. Starting the Project

Before starting the project, make sure Docker and Docker Compose are installed and running.

From the root directory of the project:

```bash
make
```
This builds the required Docker images and starts the services.

Alternatively:
```bash
make up
```
The containers should start automatically.
To check their status:
```bash
make ps
```
You should see:
```bash
nginx
wordpress
mariadb
```
# 3. Stopping the Project
To stop the running containers:
```bash
make stop
```
This stops the services without removing the containers or persistent data.

To stop and remove the containers:
```bash
make down
```
Persistent volumes are normally kept when using ```make down```.

This means that stopping the project does not delete the WordPress website or MariaDB database.

# 4. Restarting the Project
After stopping the project, start it again with:
```bash
make up
```
Because WordPress and MariaDB data are stored in persistent volumes, the existing website and database should still be available.

A complete rebuild can be performed with:
```bash
make re
```
Be aware that the exact behavior of ```make re``` depends on the Makefile configuration.

# 5. Accessing the Website
The website is available through HTTPS using the configured domain.

The expected domain format is:
```
https://YOUR_LOGIN.42.fr
```
For example:
```
https://aberrami.42.fr
```
The domain must resolve to the machine running the project.

For local development, the /etc/hosts file can contain:
```
127.0.0.1 YOUR_LOGIN.42.fr
```

# 6. Accessing the WordPress Administration Panel
The WordPress administration panel is available at:
```
https://YOUR_LOGIN.42.fr/wp-admin
```
Use the WordPress administrator credentials configured during the initial installation.

# 7. Credentials
Credentials are configured through the project's environment and/or secret files.

The main configuration file is:
```
srcs/.env
```
It contains non-public configuration such as:
```
DOMAIN_NAME=YOUR_LOGIN.42.fr
MYSQL_DATABASE=wordpress
MYSQL_USER=...
WP_TITLE=...
WP_ADMIN_USER=...
WP_ADMIN_EMAIL=...
WP_USER=...
WP_USER_EMAIL=...
```
Passwords and other sensitive information should not be committed to Git.

If Docker secrets are used, they are stored in:
```
secrets/
```
For example:
```
secrets/
├── db_password.txt
├── db_root_password.txt
└── credentials.txt
```
The exact filenames depend on the project's configuration.

## Important Credential Rules

Never:

- Publish passwords in the repository.
- Put passwords directly in Dockerfiles.
- Commit .env when it contains real passwords.
- Commit files from secrets/.
- Share administrator credentials publicly.

If credentials need to be changed, update the appropriate environment or secret configuration and restart/reinitialize the relevant service as required.

# 8. Checking That the Services Are Running

The easiest way to check the stack is:
```bash
make ps
```
All three mandatory containers should be running:
```
nginx
wordpress
mariadb
```
You can also use:
```bash
docker ps
```

# 9. Checking Service Logs
To view logs for all services:
```bash
make logs
```
To inspect a specific service:
```bash
docker compose -f srcs/docker-compose.yml logs nginx
```
```bash
docker compose -f srcs/docker-compose.yml logs wordpress
```
```bash
docker compose -f srcs/docker-compose.yml logs mariadb
```
Logs are useful when a service fails to start or when the website cannot be accessed.