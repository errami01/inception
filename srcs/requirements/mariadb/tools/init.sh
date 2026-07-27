#!/bin/bash

set -e

DB_DIR="/var/lib/mysql"
echo "[INFO] Preparing runtime directories..."
mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
echo "[INFO] Starting MariaDB container..."

# Initialize the database only on the first run
if [ ! -d "$DB_DIR/mysql" ]; then
    echo "[INFO] First startup detected."
    echo "[INFO] Initializing database..."

    mariadb-install-db \
        --user=mysql \
        --datadir="$DB_DIR"

    echo "[INFO] Starting temporary MariaDB server..."

    mariadbd \
        --user=mysql \
        --datadir="$DB_DIR" \
        --skip-networking \
        --skip-grant-tables \
        &

    PID="$!"

    echo "[INFO] Waiting for MariaDB..."

    until mariadb-admin --no-defaults ping --silent; do
        sleep 1
    done

    echo "[INFO] Creating database and users..."

    # We use mariadb --no-defaults to bypass socket restrictions safely
    mariadb --no-defaults << EOF
-- 1. This unlocks user creation statements while --skip-grant-tables is active
FLUSH PRIVILEGES;

-- 2. Create your WordPress schema
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- 3. Create your custom user and assign rights
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';

-- 4. Update root to use password authentication, stripping unix_socket restrictions
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- 5. Commit all changes to disk
FLUSH PRIVILEGES;
EOF

    echo "[INFO] Stopping temporary server..."

    # The root user now has a password, so pass it cleanly to shut down
    mariadb-admin --no-defaults -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown

    wait "$PID"

    echo "[INFO] MariaDB initialization completed."
else
    echo "[INFO] Existing database detected."
fi

echo "[INFO] Starting MariaDB..."

exec mariadbd \
    --user=mysql \
    --datadir="$DB_DIR"
