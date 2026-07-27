#!/bin/bash

set -e

echo "[INFO] Starting WordPress setup..."


echo "[INFO] Waiting for MariaDB..."

until mariadb \
    -hmariadb \
    -u"$MYSQL_USER" \
    -p"$MYSQL_PASSWORD" \
    -e "SELECT 1;" >/dev/null 2>&1
do
    sleep 5
done

echo "[INFO] MariaDB is ready."
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "[INFO] Downloading WordPress..."

    wp core download \
        --path=/var/www/html \
        --allow-root
    wp config create \
        --path=/var/www/html \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost=mariadb \
        --allow-root
    wp core install \
        --path=/var/www/html \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --allow-root
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --path=/var/www/html \
        --allow-root
    chown -R www-data:www-data /var/www/html
fi
sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|g' /etc/php/8.2/fpm/pool.d/www.conf
echo "[INFO] Launching PHP-FPM..."
exec php-fpm8.2 -F