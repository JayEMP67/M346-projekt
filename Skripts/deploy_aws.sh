#!/bin/bash
# deploy_aws.sh
# AUTOMATED DEPLOYMENT SCRIPT

# Configuration
KEY_NAME="NextcloudProjectKey"
SG_WEB="Nextcloud-Web-SG"
SG_DB="Nextcloud-DB-SG"
AMI_ID=$(aws ec2 describe-images --owners 099720109477 --filters "Name=name,Values=ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" "Name=state,Values=available" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)
INSTANCE_TYPE="t2.micro"

# Define Colors for better output (requires tput)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
MAGENTA=$(tput setaf 5)
CYAN=$(tput setaf 6)
NC=$(tput sgr0) # No Color

# --- Start Script ---
echo -e "${BLUE}================================================================${NC}"
echo -e "${CYAN} Nextcloud AWS Deployment Start ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "Region: ${YELLOW}$(aws configure get region)${NC}"
echo -e "AMI Used: ${YELLOW}$AMI_ID${NC}"
echo ""

# 1. Create SSH Key (if not exists)
echo -e "${MAGENTA}>> 1. Checking/Creating SSH Key Pair (${KEY_NAME})...${NC}"
if ! aws ec2 describe-key-pairs --key-names "$KEY_NAME" >/dev/null 2>&1; then
	echo -e "  ${GREEN}✓ Creating Key Pair and saving to ${KEY_NAME}.pem${NC}"
    aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
    chmod 400 "${KEY_NAME}.pem"
else
	echo -e "  ${YELLOW}ℹ Key Pair ${KEY_NAME} already exists. Skipping creation.${NC}"
    echo "Key Pair $KEY_NAME already exists."
fi
	echo ""

# 2. Create Security Groups
echo -e "${MAGENTA}>> 2. Creating Security Groups...${NC}"

# Web Server SG (Allow HTTP + SSH)
echo -n "  Creating Web Server SG (${SG_WEB})..."
aws ec2 create-security-group --group-name "$SG_WEB" --description "Security group for Webserver" >/dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-name "$SG_WEB" --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-name "$SG_WEB" --protocol tcp --port 80 --cidr 0.0.0.0/0 >/dev/null 2>&1
echo -e " ${GREEN}Done.${NC}"

# Database SG (Allow SSH + MySQL ONLY from Webserver)
echo -n "  Creating Database SG (${SG_DB})..."
aws ec2 create-security-group --group-name "$SG_DB" --description "Security group for Database" >/dev/null 2>&1
aws ec2 authorize-security-group-ingress --group-name "$SG_DB" --protocol tcp --port 22 --cidr 0.0.0.0/0 >/dev/null 2>&1
# Allow traffic on port 3306 specifically from the Web Security Group
aws ec2 authorize-security-group-ingress --group-name "$SG_DB" --protocol tcp --port 3306 --source-group "$SG_WEB" >/dev/null 2>&1
echo -e " ${GREEN}Done.${NC}"
echo ""

# 3. Launch Database Instance
echo -e "${MAGENTA}>> 3. Launching Database Server (Nextcloud-DB)...${NC}"
DB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-groups "$SG_DB" \
    --user-data file://install_db.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Nextcloud-DB}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "  Instance ID: ${YELLOW}$DB_INSTANCE_ID${NC}"
echo -n "  Waiting for instance to start..."
aws ec2 wait instance-running --instance-ids "$DB_INSTANCE_ID"
DB_PRIVATE_IP=$(aws ec2 describe-instances --instance-ids "$DB_INSTANCE_ID" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
echo -e " ${GREEN}Done.${NC}"
echo -e "  Database Private IP: ${GREEN}$DB_PRIVATE_IP${NC}"
echo ""

# 4. Prepare Web User Data (Inject DB IP)
echo -e "${MAGENTA}>> 4. Preparing Web Server Configuration...${NC}"
# We create a temporary file with the correct DB IP
sed "s/DB_HOST_PLACEHOLDER/$DB_PRIVATE_IP/" install_web.sh > install_web_final.sh
echo -e "  ${GREEN}✓ Injected Database IP into install_web_final.sh${NC}"
echo ""

# 5. Launch Web Server Instance
echo -e "${MAGENTA}>> 5. Launching Web Server (Nextcloud-Web)...${NC}"
WEB_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id "$AMI_ID" \
    --count 1 \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-groups "$SG_WEB" \
    --user-data file://install_web_final.sh \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Nextcloud-Web}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo -e "  Instance ID: ${YELLOW}$WEB_INSTANCE_ID${NC}"
echo -n "  Waiting for instance to start..."
aws ec2 wait instance-running --instance-ids "$WEB_INSTANCE_ID"
WEB_PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$WEB_INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
echo -e " ${GREEN}Done.${NC}"
echo ""

echo -e "${BLUE}================================================================${NC}"
echo -e "${CYAN}🚀 DEPLOYMENT COMPLETE! ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo -e "Webserver Public IP: ${GREEN}$WEB_PUBLIC_IP${NC}"
echo -e "Database Private IP: ${GREEN}$DB_PRIVATE_IP${NC}"
echo ""
echo -e "${YELLOW}!!! NEXT STEP - CHECK INSTALLATION STATUS !!!${NC}"
echo "-------------------------------------------------------"
echo -e "1. ${YELLOW}Wait 2-3 minutes${NC} for the User Data scripts (install_db.sh, install_web_final.sh) to finish."
echo "2. Access Nextcloud in your browser using the IP above:"
echo -e "   ${CYAN}http://${WEB_PUBLIC_IP}${NC}"
echo "3. ${YELLOW}To retrieve the MySQL credentials (and debug)${NC}, check the Webserver's System Log:"
echo "   - Go to AWS Console > EC2 > Select 'Nextcloud-Web'"
echo "   - Actions > Monitor and troubleshoot > Get system log"
echo "4. Use your SSH Key to log in (if needed):"
echo -e "   ${CYAN}ssh -i ${KEY_NAME}.pem ubuntu@${WEB_PUBLIC_IP}${NC}"
echo "-------------------------------------------------------"

# Cleanup temp file
rm install_web_final.sh
