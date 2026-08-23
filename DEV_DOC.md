# Developer Documentation

## 1. Overview

This document explains how to set up, build, run, manage, and troubleshoot the Inception project as a developer.

The project is a Docker Compose infrastructure composed of three mandatory services:

- **NGINX** — the only public entrypoint, providing HTTPS/TLS.
- **WordPress + PHP-FPM** — the application layer.
- **MariaDB** — the WordPress database.

The services run in separate containers and communicate through a dedicated Docker network. WordPress files and MariaDB data are stored in separate persistent Docker named volumes.

The project requirements specify that the infrastructure must be run in a virtual machine, that Docker Compose must be used, and that the persistent volumes must store their data under `/home/<login>/data` on the host. See the project subject for the complete requirements. 

---

## 2. Prerequisites

Before setting up the project, make sure the development machine is ready.

### Required

- A Linux virtual machine for the final project/evaluation.
- Docker Engine.
- Docker Compose v2 (`docker compose`).
- Git.
- `make`.
- Sufficient disk space for Docker images, containers, and persistent data.
- `sudo` access if Docker or `/etc/hosts` configuration requires it.

Verify Docker:

```bash
docker --version
docker compose version
```

Verify Make:

```bash
make --version
```


---

## 3. Project Structure

The expected high-level structure is:

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

The Makefile is located at the repository root. Docker Compose configuration and service configuration are located under `srcs/`.

---

## 4. Clone and Enter the Project

Clone the repository and enter it:

```bash
git clone <repository-url>
cd inception
```

Do not commit passwords, API keys, or other credentials to Git.

---

## 5. Configuration

### 5.1 Environment file

Create the environment file:

```text
srcs/.env
```

The exact variables depend on the implementation, but a typical configuration contains:

```dotenv
DOMAIN_NAME=yourlogin.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=change_me
MYSQL_ROOT_PASSWORD=change_me

WP_TITLE=Inception
WP_ADMIN_USER=your_user
WP_ADMIN_PASSWORD=change_me
WP_ADMIN_EMAIL=you@example.com

WP_USER=regular_user
WP_USER_PASSWORD=change_me
WP_USER_EMAIL=user@example.com
```

Use your actual 42 login for `DOMAIN_NAME`.

The administrator username must not contain `admin` or `administrator`, as required by the project subject.

### 5.2 Secrets

Credentials should not be committed to the repository.

The subject strongly recommends Docker secrets for confidential information and explicitly states that credentials, API keys, and passwords found in the Git repository outside properly configured secrets can cause project failure.

If the implementation uses the `secrets/` directory, keep it local and add it to `.gitignore`.

Example:

```text
secrets/
srcs/.env
```

Do not put real credentials in documentation examples.

---

## 6. Configure the Local Domain

The WordPress domain must point to the local machine.

For a local development VM, edit `/etc/hosts`:

```bash
sudo nano /etc/hosts
```

Add:

```text
127.0.0.1 yourlogin.42.fr
```

Replace `yourlogin` with the login used in `DOMAIN_NAME`.

Then the website should be reachable at:

```text
https://yourlogin.42.fr
```

The NGINX service is the only public entrypoint and exposes HTTPS on port `443`.

---

## 7. Configure Persistent Data

The project uses two separate Docker named volumes:

1. WordPress/MariaDB database data.
2. WordPress website files.

The subject requires both named volumes to store their data under:

```text
/home/<login>/data
```

On the VM, create the directories:

```bash
sudo mkdir -p /home/<login>/data/mariadb
sudo mkdir -p /home/<login>/data/wordpress
```

Replace `<login>` with your 42 login.

The Compose configuration should map the two named volumes to the corresponding host directories according to the project's implementation.

### Important

Do not confuse:

- a **Docker named volume** with
- a simple host bind mount declared directly as a service volume.

The project requires Docker named volumes, while their persistent data must reside under `/home/<login>/data`.

---

## 8. Build and Launch

The recommended entrypoint for developers is the Makefile.

From the repository root:

```bash
make
```

or:

```bash
make all
```

The Makefile should invoke Docker Compose and build the project images.

To explicitly rebuild and start:

```bash
make up
```

Equivalent Docker Compose command:

```bash
docker compose -f srcs/docker-compose.yml up --build
```

Run in detached mode if supported by the Makefile:

```bash
docker compose -f srcs/docker-compose.yml up --build -d
```

---

## 9. Verify the Stack

Check running containers:

```bash
docker compose -f srcs/docker-compose.yml ps
```

or:

```bash
docker ps
```

The mandatory stack should contain:

```text
nginx
wordpress
mariadb
```

Check all service logs:

```bash
docker compose -f srcs/docker-compose.yml logs
```

Follow logs live:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

Check an individual service:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs mariadb
```

---

## 10. Access the Containers

Open a shell inside a running container:

```bash
docker exec -it nginx bash
```

```bash
docker exec -it wordpress bash
```

```bash
docker exec -it mariadb bash
```

The exact shell available depends on the image.

Inspect running processes:

```bash
docker exec wordpress ps aux
```

Check the NGINX configuration:

```bash
docker exec nginx nginx -t
```

Check PHP-FPM:

```bash
docker exec wordpress php-fpm8.2 -t
```

The PHP-FPM version may differ depending on the Debian/PHP version used by the project.

---

## 11. Manage the Project with Make

Typical Makefile targets should include commands equivalent to:

```bash
make
make up
make down
make start
make stop
make logs
make ps
make clean
make fclean
make re
```

Their intended purposes are:

| Command | Purpose |
|---|---|
| `make` / `make all` | Build and start the complete stack |
| `make up` | Build/rebuild and start services |
| `make down` | Stop and remove containers/networks created by Compose |
| `make start` | Start existing stopped containers |
| `make stop` | Stop running containers |
| `make logs` | Follow service logs |
| `make ps` | Show Compose service status |
| `make clean` | Remove the Compose stack and, depending on implementation, its volumes |
| `make fclean` | Full cleanup, including images/volumes according to the Makefile |
| `make re` | Clean and rebuild the project |

Always inspect the Makefile before using destructive targets such as `clean` or `fclean`.

---

## 12. Manage Containers Directly with Docker Compose

Start the stack:

```bash
docker compose -f srcs/docker-compose.yml up -d
```

Rebuild images:

```bash
docker compose -f srcs/docker-compose.yml build
```

Rebuild without cache:

```bash
docker compose -f srcs/docker-compose.yml build --no-cache
```

Stop containers without removing them:

```bash
docker compose -f srcs/docker-compose.yml stop
```

Start stopped containers:

```bash
docker compose -f srcs/docker-compose.yml start
```

Stop and remove containers and the Compose network:

```bash
docker compose -f srcs/docker-compose.yml down
```

Follow logs:

```bash
docker compose -f srcs/docker-compose.yml logs -f
```

---

## 13. Manage Volumes

List Docker volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume-name>
```

The project should have separate persistent storage for:

```text
MariaDB
WordPress files
```

Do not remove these volumes during normal development if you want to preserve the database and WordPress installation.

### Destructive operation

This removes Compose-managed volumes:

```bash
docker compose -f srcs/docker-compose.yml down -v
```

This can delete the persistent application data associated with the Compose volumes. Use it only when intentionally resetting the environment.

After deleting the volumes, the next startup will behave like a fresh installation.

---

## 14. Where Project Data Is Stored

There are two important categories of data.

### MariaDB data

MariaDB stores the WordPress database in its persistent volume.

The host-side data is required by the subject to reside under:

```text
/home/<login>/data/
```

typically:

```text
/home/<login>/data/mariadb/
```

### WordPress website files

WordPress core files, plugins, themes, uploads, and `wp-config.php` are stored in the second persistent volume.

Typically:

```text
/home/<login>/data/wordpress/
```

The WordPress and NGINX containers mount the WordPress files volume so that:

- WordPress/PHP-FPM can execute and modify the application.
- NGINX can serve static files and pass PHP requests to PHP-FPM.

---

## 15. How Persistence Works

Containers are replaceable. Persistent volumes are what preserve application data.

For example:

```text
docker compose down
```

removes the containers, but normally does not remove the persistent volumes.

Starting again:

```bash
docker compose up -d
```

reuses the existing database and WordPress files.

Therefore:

```text
Container removed
       ↓
Volume remains
       ↓
Container recreated
       ↓
Existing data mounted again
```

This means the following should survive normal container recreation:

- WordPress installation.
- WordPress database.
- Uploaded media.
- Themes/plugins stored in the WordPress files volume.

Do not use `docker compose down -v` when you want to preserve this data.

---

## 16. Network Management

The services communicate through the project's custom Docker network.

List networks:

```bash
docker network ls
```

Inspect the project network:

```bash
docker network inspect inception
```

The mandatory services should be attached to the same project network.

The expected communication path is:

```text
Client
  |
  | HTTPS :443
  v
NGINX
  |
  | FastCGI
  v
WordPress / PHP-FPM
  |
  | MySQL/MariaDB
  v
MariaDB
```

Service names are used for internal Docker DNS resolution. For example, WordPress connects to MariaDB using the Compose service name rather than `localhost`.

---

## 17. Troubleshooting

### Containers are not running

```bash
docker compose -f srcs/docker-compose.yml ps
```

Then inspect logs:

```bash
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

### WordPress cannot connect to MariaDB

Check that MariaDB is running:

```bash
docker compose -f srcs/docker-compose.yml ps mariadb
```

Check the WordPress environment:

```bash
docker exec wordpress env | grep MYSQL
```

Check that both services share the project network:

```bash
docker network inspect inception
```

From the WordPress container, test MariaDB connectivity using the configured database credentials.

### NGINX is not serving the website

Check:

```bash
docker compose -f srcs/docker-compose.yml logs nginx
```

Validate NGINX:

```bash
docker exec nginx nginx -t
```

Check that WordPress is running and PHP-FPM is listening on the expected FastCGI port.

### Website disappeared after a rebuild

First check whether the persistent volumes still exist:

```bash
docker volume ls
```

Inspect them:

```bash
docker volume inspect <volume-name>
```

If `down -v`, volume removal, or manual deletion was used, the persistent data may have been intentionally deleted.

---

## 18. Clean Reinstallation

If you intentionally want to test the project from a completely empty state:

```bash
docker compose -f srcs/docker-compose.yml down -v
```

Then rebuild:

```bash
docker compose -f srcs/docker-compose.yml up --build
```

Be aware that this destroys the Docker volumes managed by Compose. It should be used as a development/reset operation, not as a normal shutdown procedure.

---
