#!/bin/bash
set -e

APP_USER="$USER"
BASE_DIR="/home/$APP_USER/DevOps"
SRC_DIR="$BASE_DIR/src"
LOG_FILE="/tmp/setup-$(date +%Y%m%d-%H%M%S).log"

exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== BẮT ĐẦU CÀI ĐẶT MÔI TRƯỜNG ==="

sudo apt update -y

sudo apt install -y curl git build-essential wget ca-certificates gnupg lsb-release software-properties-common ufw

# Firewall - reset về mặc định, chỉ mở 22,80,443
sudo ufw --force disable
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
echo "y" | sudo ufw enable
sudo ufw status verbose

# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Nginx
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

# MongoDB 6.0
UBUNTU_CODENAME=$(lsb_release -cs)
wget -qO - https://pgp.mongodb.com/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $UBUNTU_CODENAME/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null
sudo apt update -y
sudo apt install -y mongodb-org
sudo systemctl enable mongod
sudo systemctl start mongod

# PM2
sudo npm install -g pm2
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u $APP_USER --hp /home/$APP_USER

# Docker
sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo usermod -aG docker $APP_USER
sudo systemctl enable docker
sudo systemctl start docker

# Docker Compose (standalone) - optional, nhưng giữ để tương thích
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d'"' -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Tạo thư mục uploads
mkdir -p "$SRC_DIR/public/uploads"
sudo chown -R $APP_USER:$APP_USER "$SRC_DIR/public"
chmod 755 "$SRC_DIR/public/uploads"

# Cài dependencies
if [ -f "$BASE_DIR/package.json" ]; then
    cd "$BASE_DIR"
    npm install
else
    echo "WARNING: package.json not found at $BASE_DIR"
fi

# Khởi động ứng dụng với PM2
if [ -f "$SRC_DIR/main.js" ]; then
    cd "$BASE_DIR"
    pm2 start "$SRC_DIR/main.js" --name devops-app
    pm2 save
else
    echo "WARNING: main.js not found at $SRC_DIR"
fi

echo "=== CÀI ĐẶT HOÀN TẤT ==="
echo "Log file: $LOG_FILE"