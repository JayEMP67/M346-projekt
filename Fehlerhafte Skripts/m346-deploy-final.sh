#!/bin/bash

################################################################################
# M346 NEXTCLOUD DEPLOYMENT - AUTO-CONFIG VERSION
# 
# ✅ Mit automatischer AWS Credentials Konfiguration
# 
# Verwendung:
#   chmod +x m346-deploy-final.sh
#   ./m346-deploy-final.sh
################################################################################

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[*]${NC} $1"; }
log_ok() { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_err() { echo -e "${RED}[✗]${NC} $1"; exit 1; }
log_header() { echo -e "\n${MAGENTA}═══════════════════════════════════════════${NC}\n${MAGENTA}$1${NC}\n${MAGENTA}═══════════════════════════════════════════${NC}\n"; }

AWS_REGION="us-east-1"
AWS_KEY_NAME="m346-nextcloud"
AWS_IMAGE_ID="ami-0c02fb55956c7d316"
AWS_INSTANCE_TYPE="t2.small"

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   M346 NEXTCLOUD DEPLOYMENT - AUTO CONFIG                  ║"
echo "║   Production Ready with Credential Setup                   ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SCHRITT 1: AWS VORAUSSETZUNGEN & CREDENTIALS
# ============================================================================

log_header "SCHRITT 1: AWS CLI & CREDENTIALS"

log_info "Prüfe AWS CLI..."
[ -x "$(command -v aws)" ] || log_err "AWS CLI nicht installiert! Bitte installieren: https://aws.amazon.com/de/cli/"
log_ok "AWS CLI OK"

log_info "Prüfe AWS Credentials..."

# Versuche zu verbinden
if ! aws sts get-caller-identity &>/dev/null 2>&1; then
    log_warn "AWS Credentials nicht konfiguriert!"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}CREDENTIALS SETUP${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Bitte geben Sie Ihre AWS Credentials ein:"
    echo "(Diese erhalten Sie von Ihrer Lehrperson im voclabs Account)"
    echo ""
    
    read -p "▸ AWS Access Key ID: " AWS_ACCESS_KEY
    read -sp "▸ AWS Secret Access Key: " AWS_SECRET_KEY
    echo ""
    
    if [ -z "$AWS_ACCESS_KEY" ] || [ -z "$AWS_SECRET_KEY" ]; then
        log_err "Credentials dürfen nicht leer sein!"
    fi
    
    # Konfiguriere AWS CLI
    log_info "Konfiguriere AWS CLI..."
    aws configure set aws_access_key_id "$AWS_ACCESS_KEY"
    aws configure set aws_secret_access_key "$AWS_SECRET_KEY"
    aws configure set region "$AWS_REGION"
    aws configure set output "json"
    log_ok "AWS CLI konfiguriert"
    echo ""
fi

# Teste Verbindung
if ! aws sts get-caller-identity &>/dev/null 2>&1; then
    log_err "AWS Credentials ungültig! Bitte prüfe deine Eingabe."
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
log_ok "AWS Credentials OK (Account: $ACCOUNT_ID)"

log_info "Prüfe Region..."
aws ec2 describe-regions --region-names "$AWS_REGION" &>/dev/null || log_err "Region ungültig!"
log_ok "Region $AWS_REGION OK"

# ============================================================================
# SCHRITT 2: SSH KEY SETUP
# ============================================================================

log_header "SCHRITT 2: SSH KEY SETUP"

if [ ! -f "${AWS_KEY_NAME}.pem" ]; then
    log_info "SSH Key wird erstellt..."
    aws ec2 describe-key-pairs --key-names "$AWS_KEY_NAME" --region "$AWS_REGION" &>/dev/null 2>&1 && \
        aws ec2 delete-key-pair --key-name "$AWS_KEY_NAME" --region "$AWS_REGION" 2>/dev/null
    
    aws ec2 create-key-pair \
        --key-name "$AWS_KEY_NAME" \
        --region "$AWS_REGION" \
        --query 'KeyMaterial' \
        --output text > "${AWS_KEY_NAME}.pem"
    
    chmod 400 "${AWS_KEY_NAME}.pem"
    log_ok "SSH Key erstellt: ${AWS_KEY_NAME}.pem"
else
    log_ok "SSH Key existiert bereits"
fi

# ============================================================================
# SCHRITT 3: DEFAULT VPC SETUP
# ============================================================================

log_header "SCHRITT 3: VPC UND SUBNET"

log_info "Suche Default-Subnet..."
SUBNET_ID=$(aws ec2 describe-subnets \
    --region "$AWS_REGION" \
    --query 'Subnets[0].SubnetId' \
    --output text 2>/dev/null || echo "None")

if [ "$SUBNET_ID" = "None" ] || [ -z "$SUBNET_ID" ]; then
    log_warn "Kein Subnet gefunden - erstelle Default VPC..."
    aws ec2 create-default-vpc --region "$AWS_REGION" 2>/dev/null || true
    sleep 5
    SUBNET_ID=$(aws ec2 describe-subnets --region "$AWS_REGION" --query 'Subnets[0].SubnetId' --output text)
fi

log_ok "Subnet gefunden: $SUBNET_ID"

VPC_ID=$(aws ec2 describe-subnets --subnet-ids "$SUBNET_ID" --region "$AWS_REGION" --query 'Subnets[0].VpcId' --output text)
SG_ID=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --region "$AWS_REGION" --query 'SecurityGroups[0].GroupId' --output text)
log_ok "VPC: $VPC_ID"
log_ok "Security Group: $SG_ID"

log_info "Konfiguriere Firewall-Regeln..."
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$AWS_REGION" 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$AWS_REGION" 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$AWS_REGION" 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 3306 --cidr 10.0.0.0/8 --region "$AWS_REGION" 2>/dev/null || true
log_ok "Firewall-Regeln konfiguriert"

# ============================================================================
# SCHRITT 4: DATENBANK-INSTANZ
# ============================================================================

log_header "SCHRITT 4: DATENBANK-INSTANZ"

log_info "Cloud-Init Skript wird übergeben..."

read -r -d '' DB_INIT <<'DBEOF' || true
#!/bin/bash
set -e
apt-get update && apt-get upgrade -y
apt-get install -y mariadb-server
sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl enable mariadb
systemctl restart mariadb
sleep 5
mysql <<'MYSQL'
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
MYSQL
mysql <<'MYSQL'
CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
CREATE USER IF NOT EXISTS 'nextcloud_user'@'%' IDENTIFIED BY 'NextCloud2025!Secure123';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud_user'@'%';
CREATE USER IF NOT EXISTS 'nextcloud_user'@'localhost' IDENTIFIED BY 'NextCloud2025!Secure123';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL
echo "DATABASE READY"
DBEOF

log_ok "DB Cloud-Init vorbereitet"

log_info "Starte DB-Instanz..."

DB_INSTANCE=$(aws ec2 run-instances \
    --image-id "$AWS_IMAGE_ID" \
    --instance-type "$AWS_INSTANCE_TYPE" \
    --key-name "$AWS_KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --user-data "$DB_INIT" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=m346-nextcloud-db}]" \
    --region "$AWS_REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

log_ok "DB-Instanz gestartet: $DB_INSTANCE"

log_info "Warte auf Instanz (60 Sekunden)..."
sleep 60

DB_IP=$(aws ec2 describe-instances \
    --instance-ids "$DB_INSTANCE" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

log_ok "DB-Instanz bereit!"
log_ok "DB Private IP: $DB_IP"

# ============================================================================
# SCHRITT 5: WEBSERVER-INSTANZ
# ============================================================================

log_header "SCHRITT 5: WEBSERVER-INSTANZ"

log_info "Cloud-Init Skript wird übergeben..."

read -r -d '' WEB_INIT <<WEBEOF || true
#!/bin/bash
set -e
exec > >(tee /var/log/nextcloud-init.log)
exec 2>&1
echo "=== NEXTCLOUD WEBSERVER START ===" && date

apt-get update && apt-get upgrade -y
echo "=== System Updated ===" && date

apt-get install -y apache2 libapache2-mod-php php php-gd php-mysql php-curl php-mbstring php-intl php-gmp php-xml php-imagick php-zip php-bcmath php-json php-opcache mariadb-client wget unzip curl
echo "=== Packages Installed ===" && date

a2enmod rewrite headers env dir mime setenvif ssl php8.1 2>/dev/null || true
echo "=== Apache Modules Enabled ===" && date

PHP_INI=\$(find /etc/php -name php.ini -path "*apache2*" 2>/dev/null | head -1)
if [ -f "\$PHP_INI" ]; then
    sed -i 's/max_execution_time = 30/max_execution_time = 300/' "\$PHP_INI"
    sed -i 's/memory_limit = 128M/memory_limit = 512M/' "\$PHP_INI"
    sed -i 's/upload_max_filesize = 2M/upload_max_filesize = 512M/' "\$PHP_INI"
    sed -i 's/post_max_size = 8M/post_max_size = 512M/' "\$PHP_INI"
fi
echo "=== PHP Configured ===" && date

systemctl stop apache2 2>/dev/null || true
systemctl enable apache2

cd /tmp && wget -q https://download.nextcloud.com/server/releases/latest.zip 2>/dev/null || wget https://download.nextcloud.com/server/releases/latest.zip
echo "=== Nextcloud Downloaded ===" && date

unzip -q latest.zip && rm latest.zip
rm -rf /var/www/nextcloud && mv nextcloud /var/www/
echo "=== Nextcloud Installed ===" && date

mkdir -p /var/www/nextcloud/data
chown -R www-data:www-data /var/www/nextcloud
find /var/www/nextcloud -type d -exec chmod 750 {} \;
find /var/www/nextcloud -type f -exec chmod 640 {} \;
chmod 755 /var/www/nextcloud && chmod 770 /var/www/nextcloud/data
echo "=== Permissions Set ===" && date

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
            RewriteRule ^ /index.php\$0 [QSA,L]
        </IfModule>
    </Directory>
    <Directory /var/www/nextcloud/data>
        Require all denied
    </Directory>
    ErrorLog \${APACHE_LOG_DIR}/nextcloud_error.log
    CustomLog \${APACHE_LOG_DIR}/nextcloud_access.log combined
</VirtualHost>
VHOST

a2dissite 000-default.conf 2>/dev/null || true
a2ensite nextcloud.conf
echo "=== Apache VirtualHost Configured ===" && date

mkdir -p /var/www/nextcloud/config
cat > /var/www/nextcloud/config/autoconfig.php <<'AUTOCONFIG'
<?php
\\\$AUTOCONFIG = array(
    'dbtype' => 'mysql',
    'dbname' => 'nextcloud',
    'dbuser' => 'nextcloud_user',
    'dbpass' => 'NextCloud2025!Secure123',
    'dbhost' => '$DB_IP',
    'dbtableprefix' => 'oc_',
    'directory' => '/var/www/nextcloud/data',
);
?>
AUTOCONFIG

chown www-data:www-data /var/www/nextcloud/config/autoconfig.php
chmod 640 /var/www/nextcloud/config/autoconfig.php
echo "=== Nextcloud Config Created ===" && date

systemctl start apache2
echo "=== APACHE STARTED ===" && date

sleep 5
systemctl restart apache2
echo "=== APACHE RESTARTED ===" && date

echo "=== NEXTCLOUD WEBSERVER READY ===" && date
WEBEOF

log_ok "Web Cloud-Init vorbereitet"

log_info "Starte Web-Instanz..."

WEB_INSTANCE=$(aws ec2 run-instances \
    --image-id "$AWS_IMAGE_ID" \
    --instance-type "$AWS_INSTANCE_TYPE" \
    --key-name "$AWS_KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --user-data "$WEB_INIT" \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=m346-nextcloud-web}]" \
    --region "$AWS_REGION" \
    --query 'Instances[0].InstanceId' \
    --output text)

log_ok "Web-Instanz gestartet: $WEB_INSTANCE"

log_info "Warte auf Instanz (90 Sekunden für Extended Startup)..."
sleep 90

WEB_IP=$(aws ec2 describe-instances \
    --instance-ids "$WEB_INSTANCE" \
    --region "$AWS_REGION" \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

log_ok "Web-Instanz bereit!"
log_ok "Web Public IP: $WEB_IP"

# ============================================================================
# EXTENDED WAIT FOR CLOUD-INIT
# ============================================================================

log_header "WARTE AUF CLOUD-INIT COMPLETION"

log_info "Überwache Cloud-Init (bis 120 Sekunden)..."
READY=0
for i in {1..120}; do
    STATUS=$(aws ec2 describe-instance-status --instance-ids "$WEB_INSTANCE" --region "$AWS_REGION" --query 'InstanceStatuses[0].SystemStatus.Status' --output text 2>/dev/null || echo "initializing")
    
    if [ "$STATUS" = "ok" ]; then
        log_ok "System Status: OK"
        READY=1
        break
    fi
    
    PERCENT=$((i * 100 / 120))
    printf "\r  [$(printf '%03d' $PERCENT)%%] Status: $STATUS (${i}/120)"
    sleep 1
done

if [ $READY -eq 0 ]; then
    log_warn "Timeout - Cloud-Init läuft möglicherweise noch"
fi

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

log_header "✅ DEPLOYMENT ABGESCHLOSSEN!"

echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✓ DATENBANK${NC}"
echo "  Instance ID: $DB_INSTANCE"
echo "  Private IP: $DB_IP"
echo ""
echo -e "${GREEN}✓ WEBSERVER${NC}"
echo "  Instance ID: $WEB_INSTANCE"
echo "  Public IP: $WEB_IP"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "${CYAN}┌─ NEXTCLOUD ZUGRIFF ────────────────────────┐${NC}"
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  URL: ${BLUE}http://$WEB_IP/${NC}"
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  ⚠️  WICHTIG:"
echo -e "${CYAN}│${NC}  • 10-15 Minuten warten"
echo -e "${CYAN}│${NC}  • Seite neu laden (Ctrl+F5)"
echo -e "${CYAN}│${NC}  • Logs mit SSH prüfen (siehe unten)"
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}└────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${CYAN}┌─ SSH ZUGRIFF ──────────────────────────────┐${NC}"
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}│${NC}  ${BLUE}ssh -i ${AWS_KEY_NAME}.pem ubuntu@$WEB_IP${NC}"
echo -e "${CYAN}│${NC}"
echo -e "${CYAN}└────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${MAGENTA}┌─ DATENBANK CREDENTIALS ─────────────────────┐${NC}"
echo -e "${MAGENTA}│${NC}"
echo -e "${MAGENTA}│${NC}  Host: $DB_IP"
echo -e "${MAGENTA}│${NC}  User: nextcloud_user"
echo -e "${MAGENTA}│${NC}  Pass: NextCloud2025!Secure123"
echo -e "${MAGENTA}│${NC}  DB:   nextcloud"
echo -e "${MAGENTA}│${NC}"
echo -e "${MAGENTA}└────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${YELLOW}┌─ DEBUG / LOGS VIA SSH ──────────────────────┐${NC}"
echo -e "${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  Installation anschauen:"
echo -e "${YELLOW}│${NC}  ${BLUE}sudo tail -f /var/log/nextcloud-init.log${NC}"
echo -e "${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  Apache Status:"
echo -e "${YELLOW}│${NC}  ${BLUE}sudo systemctl status apache2${NC}"
echo -e "${YELLOW}│${NC}"
echo -e "${YELLOW}│${NC}  Apache Fehler:"
echo -e "${YELLOW}│${NC}  ${BLUE}sudo tail -50 /var/log/apache2/error.log${NC}"
echo -e "${YELLOW}│${NC}"
echo -e "${YELLOW}└────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${RED}┌─ INSTANZEN BEENDEN (kostet Geld!) ──────────┐${NC}"
echo -e "${RED}│${NC}"
echo -e "${RED}│${NC}  ${BLUE}aws ec2 terminate-instances --instance-ids $WEB_INSTANCE $DB_INSTANCE --region $AWS_REGION${NC}"
echo -e "${RED}│${NC}"
echo -e "${RED}└────────────────────────────────────────────┘${NC}"
echo ""

echo -e "${GREEN}✓ Deployment fertig! Viel Erfolg! 🚀${NC}"
echo ""
