#!/bin/bash

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
        &

    PID="$!"

    echo "[INFO] Waiting for MariaDB..."

    until mariadb-admin ping --silent; do
        sleep 1
    done

    echo "[INFO] Creating database and users..."

    mariadb << EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES
ON \`${MYSQL_DATABASE}\`.*
TO '${MYSQL_USER}'@'%';

ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

FLUSH PRIVILEGES;
EOF

    echo "[INFO] Stopping temporary server..."

    mariadb-admin shutdown

    wait "$PID"

    echo "[INFO] MariaDB initialization completed."
else
    echo "[INFO] Existing database detected."
fi

echo "[INFO] Starting MariaDB..."

exec mariadbd \
    --user=mysql \
    --datadir="$DB_DIR"