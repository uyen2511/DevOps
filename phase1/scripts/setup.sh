#!/bin/bash
# ============================================
# 🚀 SETUP SCRIPT - PHASE 1 (FIXED PATH)
# ============================================

# =======================
# CONFIG
# =======================
APP_USER="$USER"
BASE_DIR="/home/$APP_USER/DevOps"
APP_DIR="$BASE_DIR/phase1"
SRC_DIR="$APP_DIR/src"
LOG_FILE="/tmp/setup-$(date +%Y%m%d-%H%M%S).log"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

print_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
print_step()  { echo -e "\n${BLUE}▶ $1${NC}"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# =======================
# CHECK SYSTEM
# =======================
check_system() {
    print_step "Checking system..."

    if ! grep -qi "ubuntu" /etc/os-release; then
        print_error "Only Ubuntu supported"
        exit 1
    fi

    if ! ping -c 1 google.com &>/dev/null; then
        print_error "No internet"
        exit 1
    fi

    print_info "System OK"
}

# =======================
# UPDATE
# =======================
update_system() {
    print_step "Updating system..."
    sudo apt update -y >> "$LOG_FILE" 2>&1
    sudo apt upgrade -y >> "$LOG_FILE" 2>&1
}

# =======================
# BASIC TOOLS
# =======================
install_basic_tools() {
    print_step "Installing tools..."
    sudo apt install -y curl git build-essential wget ca-certificates gnupg >> "$LOG_FILE" 2>&1
}

# =======================
# NODEJS
# =======================
install_nodejs() {
    print_step "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >> "$LOG_FILE" 2>&1
    sudo apt install -y nodejs >> "$LOG_FILE" 2>&1

    print_info "Node: $(node -v)"
}

# =======================
# NGINX
# =======================
install_nginx() {
    print_step "Installing Nginx..."
    sudo apt install -y nginx >> "$LOG_FILE" 2>&1
    sudo systemctl enable nginx
    sudo systemctl start nginx
}

# =======================
# MONGODB
# =======================
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

    sudo systemctl enable mongod
    sudo systemctl start mongod
}

# =======================
# PM2
# =======================
install_pm2() {
    print_step "Installing PM2..."
    sudo npm install -g pm2 >> "$LOG_FILE" 2>&1

    pm2 startup systemd -u $APP_USER --hp /home/$APP_USER >> "$LOG_FILE" 2>&1
}

# =======================
# INSTALL DEPENDENCIES
# =======================
install_project_deps() {
    print_step "Installing project dependencies..."

    if [ -f "$BASE_DIR/package.json" ]; then
        cd "$BASE_DIR" || exit
        npm install >> "$LOG_FILE" 2>&1
        print_info "Dependencies installed"
    else
        print_error "package.json not found in DevOps/"
    fi
}

# =======================
# START APP
# =======================
start_app() {
    print_step "Starting app with PM2..."

    if [ -f "$SRC_DIR/main.js" ]; then
        pm2 start "$SRC_DIR/main.js" --name devops-app
        pm2 save
        print_info "App started"
    else
        print_error "main.js not found in src/"
    fi
}

# =======================
# MAIN
# =======================
main() {
    echo "========== SETUP START =========="

    check_system
    update_system
    install_basic_tools
    install_nodejs
    install_nginx
    install_mongodb
    install_pm2

    install_project_deps
    start_app

    echo ""
    echo "========== DONE =========="
    echo "App running at: http://$(curl -s ifconfig.me):3000"
}

main