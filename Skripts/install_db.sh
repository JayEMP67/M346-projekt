#!/bin/bash
# install_db.sh
# Cloud-Init script for the DATABASE Server

# 1. Update and Install MariaDB
apt-get update -y
apt-get install -y mariadb-server

# 2. Configure Remote Access
# Allow listening on all interfaces so the Webserver can connect
sed -i "s/bind-address            = 127.0.0.1/bind-address            = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf

# 3. Restart Database
systemctl restart mariadb

# 4. Create Database and User
# We use '%' to allow connection from any IP, but AWS Security Groups will restrict this to ONLY the Webserver.
DB_NAME="nextcloud_db"
DB_USER="nextcloud_user"
DB_PASS="SecurePass2025!" # You can change this

sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS '$DB_USER'@'%' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';
FLUSH PRIVILEGES;
EOF

echo "DATABASE READY"
