#!/bin/bash
# ============================================
# setup.sh - Complete Server Setup Script
# Phase 1 - Midterm Project
# ============================================

# ------------------------------------
# Configuration
# ------------------------------------
APP_USER="$USER"
APP_DIR="/home/$APP_USER/app"
LOG_FILE="/tmp/setup-$(date +%Y%m%d-%H%M%S).log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ------------------------------------
# Helper functions
# ------------------------------------
print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ------------------------------------
# Check system
# ------------------------------------
check_system() {
    print_step "Checking system..."

    if [ ! -f /etc/os-release ] || ! grep -qi "ubuntu" /etc/os-release; then
        print_error "Only Ubuntu is supported"
        exit 1
    fi

    if ! ping -c 1 google.com > /dev/null 2>&1; then
        print_error "No internet connection"
        exit 1
    fi

    print_info "System OK"
}

# ------------------------------------
# Update system
# ------------------------------------
update_system() {
    print_step "Updating system..."
    sudo apt update -y >> "$LOG_FILE" 2>&1
    sudo apt upgrade -y >> "$LOG_FILE" 2>&1
    print_info "System updated"
}

# ------------------------------------
# Install basic tools
# ------------------------------------
install_basic_tools() {
    print_step "Installing basic tools..."
    sudo apt install -y curl git build-essential wget ca-certificates gnupg >> "$LOG_FILE" 2>&1
    print_info "Basic tools installed"
}

# ------------------------------------
# Install Node.js
# ------------------------------------
install_nodejs() {
    print_step "Installing Node.js 20 LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >> "$LOG_FILE" 2>&1
    sudo apt install -y nodejs >> "$LOG_FILE" 2>&1

    print_info "Node: $(node -v)"
    print_info "npm: $(npm -v)"
}

# ------------------------------------
# Install Nginx
# ------------------------------------
install_nginx() {
    print_step "Installing Nginx..."
    sudo apt install -y nginx >> "$LOG_FILE" 2>&1

    sudo systemctl start nginx
    sudo systemctl enable nginx

    print_info "Nginx running"
}

# ------------------------------------
# Install MongoDB (dynamic Ubuntu version)
# ------------------------------------
install_mongodb() {
    print_step "Installing MongoDB..."

    UBUNTU_CODENAME=$(lsb_release -cs)

    wget -qO - https://pgp.mongodb.com/server-6.0.asc | \
        sudo gpg --dearmor -o /usr/share/keyrings/mongodb-server-6.0.gpg

    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] \
https://repo.mongodb.org/apt/ubuntu $UBUNTU_CODENAME/mongodb-org/6.0 multiverse" | \
        sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null

    sudo apt update -y >> "$LOG_FILE" 2>&1
    sudo apt install -y mongodb-org >> "$LOG_FILE" 2>&1

    sudo systemctl start mongod
    sudo systemctl enable mongod

    print_info "MongoDB installed"
}

# ------------------------------------
# Install PM2
# ------------------------------------
install_pm2() {
    print_step "Installing PM2..."
    sudo npm install -g pm2 >> "$LOG_FILE" 2>&1

    pm2 startup systemd -u $APP_USER --hp /home/$APP_USER >> "$LOG_FILE" 2>&1

    print_info "PM2: $(pm2 --version)"
}

# ------------------------------------
# Create directories
# ------------------------------------
create_directories() {
    print_step "Creating directories..."

    mkdir -p "$APP_DIR"/{logs,uploads,data,temp,config}

    chmod -R 755 "$APP_DIR"

    print_info "App dir: $APP_DIR"
}

# ------------------------------------
# Create config templates
# ------------------------------------
create_config_templates() {
    print_step "Creating config templates..."

    cat > "$APP_DIR/config/.env.example" << EOF
PORT=3000
NODE_ENV=production
MONGO_URI=mongodb://localhost:27017/products_db
SESSION_SECRET=change-this
EOF

    cat > "$APP_DIR/config/ecosystem.config.js" << EOF
module.exports = {
  apps: [{
    name: 'product-app',
    script: 'main.js',
    cwd: '$APP_DIR',
    instances: 1,
    autorestart: true,
    max_memory_restart: '500M',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
EOF

    cat > "$APP_DIR/config/nginx.conf" << EOF
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }

    location /uploads {
        alias $APP_DIR/uploads;
    }
}
EOF

    print_info "Config templates created"
}

# ------------------------------------
# Optional: Install project deps
# ------------------------------------
install_project_deps() {
    print_step "Checking for project..."

    if [ -f "$APP_DIR/package.json" ]; then
        print_step "Installing dependencies..."
        cd "$APP_DIR" || exit
        npm ci --only=production >> "$LOG_FILE" 2>&1
        print_info "Dependencies installed"
    else
        print_info "No project found → skip npm install"
    fi
}

# ------------------------------------
# Verify
# ------------------------------------
verify() {
    print_step "Verifying..."

    command -v node && print_info "Node OK"
    command -v nginx && print_info "Nginx OK"
    command -v mongod && print_info "MongoDB OK"
    command -v pm2 && print_info "PM2 OK"
}

# ------------------------------------
# Main
# ------------------------------------
main() {
    echo "========== SETUP START =========="

    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run as root"
        exit 1
    fi

    check_system
    update_system
    install_basic_tools
    install_nodejs
    install_nginx
    install_mongodb
    install_pm2
    create_directories
    create_config_templates
    install_project_deps
    verify

    echo ""
    echo "========== DONE =========="
    echo "App directory: $APP_DIR"
    echo "Log file: $LOG_FILE"
    echo ""
    echo "Next steps:"
    echo "1. Copy your code to $APP_DIR"
    echo "2. cd $APP_DIR && npm install"
    echo "3. pm2 start config/ecosystem.config.js"
}

main