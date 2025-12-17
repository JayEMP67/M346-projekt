#!/bin/bash

################################################################################
# M346 NEXTCLOUD DEPLOYMENT - ALLES-IN-EINEM SKRIPT (VERBESSERT)
# 
# Dieser Skript macht ALLES:
# 1. Prüft Voraussetzungen
# 2. Erstellt SSH Key (falls nötig)
# 3. Deployed Nextcloud auf AWS
# 4. Zeigt IPs und Infos am Ende
#
# REGION: us-east-1 (für dieses Projekt)
#
# Verwendung:
#   chmod +x m346-deploy.sh
#   ./m346-deploy.sh
################################################################################

set -e

# FARBEN
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# FUNKTIONEN
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# KONFIGURATION - US-EAST-1
AWS_REGION="us-east-1"
AWS_KEY_NAME="m346-nextcloud"
AWS_IMAGE_ID="ami-0e86e5bf3136897ad"  # Ubuntu 22.04 LTS in us-east-1
AWS_INSTANCE_TYPE="t2.small"
PROJECT_TAG="m346-nextcloud"

DB_PASS="NextCloud2025!Secure123"
NC_ADMIN_PASS="AdminPass2025!Secure"

# Arbeitsverzeichnis
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

# ============================================================================
# SCHRITT 1: PRÜFE VORAUSSETZUNGEN
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║         M346 NEXTCLOUD DEPLOYMENT STARTER                  ║"
echo "║         Region: us-east-1                                  ║"
echo "║         Alles-in-einem Skript (VERBESSERT)                 ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log_info "Schritt 1: Prüfe Voraussetzungen..."

# AWS CLI
if ! command -v aws &> /dev/null; then
    log_err "AWS CLI nicht installiert! Installation: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi
log_ok "AWS CLI installiert"

# AWS Credentials
if ! aws sts get-caller-identity &> /dev/null 2>&1; then
    log_warn "AWS Credentials nicht konfiguriert - starten Sie aws configure"
    aws configure
fi
log_ok "AWS Credentials konfiguriert"

# AWS Region prüfen
if ! aws ec2 describe-regions --region-names "$AWS_REGION" &> /dev/null 2>&1; then
    log_err "AWS Region '$AWS_REGION' ungültig"
fi
log_ok "AWS Region $AWS_REGION ist gültig"

# ============================================================================
# SCHRITT 2: SSH KEY ERSTELLEN
# ============================================================================

echo ""
log_info "Schritt 2: SSH Key Setup..."

if [ ! -f "${AWS_KEY_NAME}.pem" ]; then
    log_warn "SSH Key Datei ${AWS_KEY_NAME}.pem existiert nicht - erstelle neue..."
    
    # Prüfe ob Key in AWS existiert
    if aws ec2 describe-key-pairs --key-names "$AWS_KEY_NAME" --region "$AWS_REGION" &> /dev/null 2>&1; then
        log_warn "Key existiert bereits in AWS aber nicht lokal - lösche und erstelle neu..."
        aws ec2 delete-key-pair --key-name "$AWS_KEY_NAME" --region "$AWS_REGION" 2>/dev/null || true
    fi
    
    # Erstelle neuen Key
    aws ec2 create-key-pair \
        --key-name "$AWS_KEY_NAME" \
        --region "$AWS_REGION" \
        --query 'KeyMaterial' \
        --output text > "${AWS_KEY_NAME}.pem"
    
    chmod 400 "${AWS_KEY_NAME}.pem"
    log_ok "SSH Key erstellt: ${AWS_KEY_NAME}.pem"
else
    log_ok "SSH Key existiert bereits: ${AWS_KEY_NAME}.pem"
fi

# ============================================================================
# SCHRITT 3: SECURITY GROUP
# ============================================================================

echo ""
log_info "Schritt 3: Security Group Setup..."

SG_NAME="m346-nextcloud-sg"

# Prüfe ob Security Group existiert
if aws ec2 describe-security-groups --group-names "$SG_NAME" --region "$AWS_REGION" &> /dev/null 2>&1; then
    log_ok "Security Group existiert bereits: $SG_NAME"
    SG_ID=$(aws ec2 describe-security-groups --group-names "$SG_NAME" --region "$AWS_REGION" --query 'SecurityGroups[0].GroupId' --output text)
else
    log_warn "Security Group nicht vorhanden - erstelle..."
    
    SG_ID=$(aws ec2 create-security-group \
        --group-name "$SG_NAME" \
        --description "M346 Nextcloud Security Group" \
        --region "$AWS_REGION" \
        --query 'GroupId' \
        --output text)
    
    log_ok "Security Group erstellt: $SG_ID"
    
    # Firewall-Regeln
    log_info "Füge Firewall-Regeln hinzu..."
    
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp --port 22 --cidr 0.0.0.0/0 \
        --region "$AWS_REGION" 2>/dev/null || true
    
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp --port 80 --cidr 0.0.0.0/0 \
        --region "$AWS_REGION" 2>/dev/null || true
    
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp --port 443 --cidr 0.0.0.0/0 \
        --region "$AWS_REGION" 2>/dev/null || true
    
    aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp --port 3306 \
        --source-group "$SG_ID" \
        --region "$AWS_REGION" 2>/dev/null || true
    
    log_ok "Firewall-Regeln hinzugefügt"
fi

# ============================================================================
# SCHRITT 4: DATENBANK-SKRIPT ERSTELLEN
# ============================================================================

echo ""
log_info "Schritt 4: Cloud-Init Skripte vorbereiten..."

# Datenbank Cloud-Init Skript
cat > "$WORK_DIR/db-userdata.txt" <<'DBSCRIPT'
#!/bin/bash
set -e
apt update && apt upgrade -y
apt install -y mariadb-server
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl enable mariadb
systemctl restart mariadb
sleep 3
mysql <<'MYSQL_EOF'
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
MYSQL_EOF
mysql <<'MYSQL_EOF'
CREATE DATABASE IF NOT EXISTS `nextcloud` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS 'nextcloud_user'@'%' IDENTIFIED BY 'NextCloud2025!Secure123';
GRANT ALL PRIVILEGES ON `nextcloud`.* TO 'nextcloud_user'@'%';
CREATE USER IF NOT EXISTS 'nextcloud_user'@'localhost' IDENTIFIED BY 'NextCloud2025!Secure123';
GRANT ALL PRIVILEGES ON `nextcloud`.* TO 'nextcloud_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_EOF
echo "Database installation complete!"
DBSCRIPT

log_ok "DB Cloud-Init Skript erstellt"

# Webserver Cloud-Init - Datei erstellen
cat > "$WORK_DIR/web-userdata.txt" <<'WEBSCRIPT'
#!/bin/bash
set -e
apt update && apt upgrade -y
apt install -y apache2 libapache2-mod-php mariadb-client php php-gd php-mysql php-curl php-mbstring php-intl php-gmp php-xml php-imagick php-zip php-bcmath unzip wget

a2enmod rewrite headers env dir mime setenvif ssl

PHP_INI=/etc/php/$(php -r 'echo PHP_VERSION_ID;' | cut -c 1-3 | sed 's/.$/').0/apache2/php.ini
if [ -f "$PHP_INI" ]; then
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' "$PHP_INI"
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' "$PHP_INI"
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 512M/' "$PHP_INI"
    sed -i 's/post_max_size = 8M/post_max_size = 512M/' "$PHP_INI"
fi

systemctl enable apache2
systemctl restart apache2

cd /tmp
wget -q -O nextcloud-latest.zip https://download.nextcloud.com/server/releases/latest.zip
unzip -q nextcloud-latest.zip

rm -rf /var/www/nextcloud
mv nextcloud /var/www/nextcloud

mkdir -p /var/www/nextcloud/data
chown -R www-data:www-data /var/www/nextcloud
find /var/www/nextcloud -type d -exec chmod 750 {} \;
find /var/www/nextcloud -type f -exec chmod 640 {} \;
chmod 755 /var/www/nextcloud
chmod 770 /var/www/nextcloud/data

cat > /etc/apache2/sites-available/nextcloud.conf <<'VHOST'
<VirtualHost *:80>
    ServerName _default_
    DocumentRoot /var/www/nextcloud
    <Directory /var/www/nextcloud>
        Require all granted
        AllowOverride All
        Options FollowSymLinks MultiViews
        <IfModule mod_rewrite.c>
            RewriteEngine On
            RewriteBase /
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteCond %{REQUEST_FILENAME} !-d
            RewriteRule ^ /index.php$0 [QSA,L]
        </IfModule>
    </Directory>
    <Directory /var/www/nextcloud/data>
        Require all denied
    </Directory>
    ErrorLog ${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog ${APACHE_LOG_DIR}/nextcloud_access.log combined
    <IfModule mod_headers.c>
        Header add X-Content-Type-Options "nosniff"
        Header add X-Frame-Options "SAMEORIGIN"
        Header add X-XSS-Protection "1; mode=block"
    </IfModule>
</VirtualHost>
VHOST

a2dissite 000-default.conf || true
a2ensite nextcloud.conf
systemctl reload apache2

mkdir -p /var/www/nextcloud/config
cat > /var/www/nextcloud/config/autoconfig.php <<'AUTOCONFIG'
<?php
$AUTOCONFIG = array(
    'dbtype' => 'mysql',
    'dbname' => 'nextcloud',
    'dbuser' => 'nextcloud_user',
    'dbpass' => 'NextCloud2025!Secure123',
    'dbhost' => 'DB_IP_PLACEHOLDER',
    'dbtableprefix' => 'oc_',
    'directory' => '/var/www/nextcloud/data',
);
?>
AUTOCONFIG

chown www-data:www-data /var/www/nextcloud/config/autoconfig.php
chmod 640 /var/www/nextcloud/config/autoconfig.php

WEB_IP=$(hostname -I | awk '{print $1}')
echo "Installation complete! Access: http://$WEB_IP/"
WEBSCRIPT

log_ok "Web Cloud-Init Skript erstellt"

# Dateien überprüfen
if [ ! -f "$WORK_DIR/db-userdata.txt" ] || [ ! -f "$WORK_DIR/web-userdata.txt" ]; then
    log_err "Cloud-Init Dateien nicht erstellt!"
fi
log_ok "Cloud-Init Dateien verifiziert"

# ============================================================================
# SCHRITT 5: DATENBANK-INSTANZ STARTEN
# ============================================================================

echo ""
log_info "Schritt 5: Starte Datenbank-Instanz..."

DB_INSTANCE=$(aws ec2 run-instances \
    --image-id "$AWS_IMAGE_ID" \
    --instance-type "$AWS_INSTANCE_TYPE" \
    --key-name "$AWS_KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --user-data "file://$WORK_DIR/db-userdata.txt" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-db},{Key=Project,Value=$PROJECT_TAG}]" \
    --region "$AWS_REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

log_ok "Datenbank-Instanz gestartet: $DB_INSTANCE"

# Warte auf IP
log_info "Warte auf IP-Adresse (ca. 30 Sekunden)..."
sleep 30

DB_IP=$(aws ec2 describe-instances \
    --instance-ids "$DB_INSTANCE" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

log_ok "Datenbank-IP: $DB_IP"

# ============================================================================
# SCHRITT 6: WEBSERVER-SKRIPT MIT DB-IP ERSTELLEN
# ============================================================================

echo ""
log_info "Schritt 6: Webserver Cloud-Init mit DB-IP vorbereiten..."

# Webserver Datei mit DB IP ersetzen
sed "s/DB_IP_PLACEHOLDER/$DB_IP/g" "$WORK_DIR/web-userdata.txt" > "$WORK_DIR/web-userdata-final.txt"

log_ok "Webserver Cloud-Init Skript mit DB-IP aktualisiert"

# ============================================================================
# SCHRITT 7: WEBSERVER-INSTANZ STARTEN
# ============================================================================

echo ""
log_info "Schritt 7: Starte Webserver-Instanz..."

WEB_INSTANCE=$(aws ec2 run-instances \
    --image-id "$AWS_IMAGE_ID" \
    --instance-type "$AWS_INSTANCE_TYPE" \
    --key-name "$AWS_KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --user-data "file://$WORK_DIR/web-userdata-final.txt" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=nextcloud-web},{Key=Project,Value=$PROJECT_TAG}]" \
    --region "$AWS_REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

log_ok "Webserver-Instanz gestartet: $WEB_INSTANCE"

# Warte auf IP
log_info "Warte auf IP-Adresse (ca. 30 Sekunden)..."
sleep 30

WEB_IP=$(aws ec2 describe-instances \
    --instance-ids "$WEB_INSTANCE" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

log_ok "Webserver-IP: $WEB_IP"

# ============================================================================
# ABSCHLUSS
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║              DEPLOYMENT ERFOLGREICH GESTARTET!             ║"
echo "║                   Region: us-east-1                        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}✓ Datenbank-Instanz:${NC} $DB_INSTANCE"
echo -e "${GREEN}✓ Webserver-Instanz:${NC} $WEB_INSTANCE"
echo ""
echo -e "${BLUE}📍 IP-ADRESSEN:${NC}"
echo "   Datenbank: $DB_IP (intern)"
echo "   Webserver: $WEB_IP"
echo ""
echo -e "${BLUE}🌐 NEXTCLOUD ZUGRIFF:${NC}"
echo "   http://$WEB_IP/"
echo ""
echo -e "${BLUE}🔑 SSH ZUGRIFF:${NC}"
echo "   ssh -i ${AWS_KEY_NAME}.pem ubuntu@$WEB_IP"
echo ""
echo -e "${YELLOW}⏳ Installation läuft noch...${NC}"
echo "   Warten Sie 10-15 Minuten bis alles fertig ist"
echo ""
echo -e "${YELLOW}📝 NÄCHSTE SCHRITTE:${NC}"
echo "   1. Öffnen Sie http://$WEB_IP im Browser"
echo "   2. Geben Sie Admin-Daten ein"
echo "   3. Klicken Sie 'Installation durchführen'"
echo "   4. Warten Sie 2-3 Minuten"
echo "   5. Sie werden zum Login weitergeleitet"
echo ""
echo -e "${YELLOW}📸 FÜR PROJEKT:${NC}"
echo "   - Screenshots machen (6 Testfälle)"
echo "   - Reflexion schreiben"
echo "   - Git Commits machen"
echo ""
echo -e "${RED}💰 KOSTENSPAREN:${NC}"
echo "   Instanzen stoppen: aws ec2 terminate-instances --instance-ids $WEB_INSTANCE $DB_INSTANCE --region $AWS_REGION"
echo ""
echo "════════════════════════════════════════════════════════════"
echo ""

log_ok "Fertig! Viel Erfolg! 🚀"
