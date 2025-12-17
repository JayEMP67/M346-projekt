#!/bin/bash
# install_web.sh
# Cloud-Init script for the WEBSERVER

# 1. Variables (injected by Master Script)
DB_HOST="DB_HOST_PLACEHOLDER"
DB_NAME="nextcloud_db"
DB_USER="nextcloud_user"
DB_PASS="SecurePass2025!"

# 2. Install Dependencies
apt-get update -y
apt-get install -y apache2 unzip php libapache2-mod-php php-gd php-mysql php-curl php-mbstring php-intl php-gmp php-bcmath php-xml php-imagick php-zip

# 3. Download Nextcloud (Archive Option)
cd /tmp
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip -d /var/www/html/
chown -R www-data:www-data /var/www/html/nextcloud

# 4. Configure Apache
cat <<EOF > /etc/apache2/sites-available/nextcloud.conf
<VirtualHost *:80>
    DocumentRoot /var/www/html/nextcloud
    <Directory /var/www/html/nextcloud/>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
    </Directory>
</VirtualHost>
EOF

a2ensite nextcloud.conf
a2enmod rewrite headers env dir mime
a2dissite 000-default.conf
systemctl restart apache2

# 5. CONSOLE OUTPUT (Required by Project)
# This will appear in the AWS System Log
echo "#######################################################"
echo "NEXTCLOUD INSTALLATION READY"
echo "Go to: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo ""
echo "Database User: $DB_USER"
echo "Database Pass: $DB_PASS"
echo "Database Name: $DB_NAME"
echo "Database Host: $DB_HOST"
echo "#######################################################"
