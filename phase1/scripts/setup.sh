#!/bin/bash
# ============================================
# setup.sh - Complete Server Setup Script
# Phase 1 - Midterm Project
# 
# This script automates the setup of an Ubuntu server
# for deploying a Node.js web application with MongoDB
# and Nginx reverse proxy.
# ============================================

# ------------------------------------
# Configuration
# ------------------------------------
APP_USER="$USER"
APP_DIR="/home/$APP_USER/app"
LOG_FILE="/tmp/setup-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ------------------------------------
# Helper functions
# ------------------------------------
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ------------------------------------
# Check system requirements
# ------------------------------------
check_system() {
    print_step "Checking system requirements..."
    
    # Check if Ubuntu
    if [ ! -f /etc/os-release ] || ! grep -qi "ubuntu" /etc/os-release; then
        print_error "This script only works on Ubuntu"
        exit 1
    fi
    
    # Check internet connectivity
    if ! ping -c 1 google.com > /dev/null 2>&1; then
        print_error "No internet connection"
        exit 1
    fi
    
    print_info "System check passed"
}

# ------------------------------------
# Update system packages
# ------------------------------------
update_system() {
    print_step "Updating system packages..."
    sudo apt update -y >> "$LOG_FILE" 2>&1
    sudo apt upgrade -y >> "$LOG_FILE" 2>&1
    print_info "System updated"
}

# ------------------------------------
# Install basic tools
# ------------------------------------
install_basic_tools() {
    print_step "Installing basic tools..."
    sudo apt install -y curl git build-essential wget >> "$LOG_FILE" 2>&1
    print_info "Basic tools installed"
}

# ------------------------------------
# Install Node.js
# ------------------------------------
install_nodejs() {
    print_step "Installing Node.js 20 LTS..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - >> "$LOG_FILE" 2>&1
    sudo apt install -y nodejs >> "$LOG_FILE" 2>&1
    
    node_version=$(node -v)
    npm_version=$(npm -v)
    print_info "Node.js $node_version installed"
    print_info "npm $npm_version installed"
}

# ------------------------------------
# Install Nginx (Reverse Proxy)
# ------------------------------------
install_nginx() {
    print_step "Installing Nginx (reverse proxy)..."
    sudo apt install -y nginx >> "$LOG_FILE" 2>&1
    
    # Start and enable Nginx
    sudo systemctl start nginx >> "$LOG_FILE" 2>&1
    sudo systemctl enable nginx >> "$LOG_FILE" 2>&1
    
    nginx_version=$(nginx -v 2>&1 | awk -F/ '{print $2}')
    print_info "Nginx $nginx_version installed and running"
}

# ------------------------------------
# Install MongoDB
# ------------------------------------
install_mongodb() {
    print_step "Installing MongoDB database..."
    
    # Import MongoDB public key
    wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | sudo apt-key add - >> "$LOG_FILE" 2>&1
    
    # Add MongoDB repository
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list > /dev/null
    
    # Install MongoDB
    sudo apt update -y >> "$LOG_FILE" 2>&1
    sudo apt install -y mongodb-org >> "$LOG_FILE" 2>&1
    
    # Start and enable MongoDB
    sudo systemctl start mongod >> "$LOG_FILE" 2>&1
    sudo systemctl enable mongod >> "$LOG_FILE" 2>&1
    
    mongodb_version=$(mongod --version | head -1)
    print_info "$mongodb_version installed and running"
}

# ------------------------------------
# Install PM2 (Process Manager)
# ------------------------------------
install_pm2() {
    print_step "Installing PM2 process manager..."
    sudo npm install -g pm2 >> "$LOG_FILE" 2>&1
    
    # Configure PM2 to start on boot
    pm2 startup systemd -u $APP_USER --hp /home/$APP_USER >> "$LOG_FILE" 2>&1
    
    pm2_version=$(pm2 --version)
    print_info "PM2 $pm2_version installed"
}

# ------------------------------------
# Install project dependencies
# ------------------------------------
install_project_deps() {
    print_step "Installing project dependencies..."
    if [ -f "package.json" ]; then
        npm install >> "$LOG_FILE" 2>&1
        print_info "Project dependencies installed"
    else
        print_error "package.json not found! Please copy project files first."
    fi
}

# ------------------------------------
# Create directory structure
# ------------------------------------
create_directories() {
    print_step "Creating application directories..."
    
    # Create main app directory
    mkdir -p $APP_DIR
    cd $APP_DIR || exit
    
    # Create required folders (as per requirements)
    mkdir -p logs        # For application logs
    mkdir -p uploads     # For file uploads feature
    mkdir -p data        # For persistent data
    mkdir -p temp        # For temporary files
    mkdir -p config      # For configuration files
    
    # Set permissions
    chmod -R 755 logs uploads data temp config
    
    print_info "Directories created:"
    print_info "  - $APP_DIR/logs   (application logs)"
    print_info "  - $APP_DIR/uploads (file uploads)"
    print_info "  - $APP_DIR/data    (persistent data)"
    print_info "  - $APP_DIR/temp    (temporary files)"
    print_info "  - $APP_DIR/config  (configuration files)"
}

# ------------------------------------
# Create configuration templates
# ------------------------------------
create_config_templates() {
    print_step "Creating configuration templates (no hard-coded credentials)..."
    
    # .env template
    cat > $APP_DIR/config/.env.example << 'EOF'
# ============================================
# Environment Configuration Template
# Copy this file to .env and update with your values
# DO NOT commit .env to version control!
# ============================================

# Application
PORT=3000
NODE_ENV=production

# Database
# Format: mongodb://username:password@host:port/database
MONGO_URI=mongodb://localhost:27017/products_db

# File Upload
MAX_FILE_SIZE=5242880  # 5MB in bytes
ALLOWED_FILE_TYPES=image/jpeg,image/png,image/gif

# Security (change in production)
SESSION_SECRET=your-secret-key-here
EOF
    
    # PM2 ecosystem file
    cat > $APP_DIR/config/ecosystem.config.js << 'EOF'
// PM2 Ecosystem Configuration
// Start with: pm2 start ecosystem.config.js
module.exports = {
  apps: [{
    name: 'product-app',
    script: 'main.js',
    cwd: '/home/ubuntu/app',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '500M',
    error_file: '/home/ubuntu/app/logs/err.log',
    out_file: '/home/ubuntu/app/logs/out.log',
    log_file: '/home/ubuntu/app/logs/combined.log',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
EOF
    
    # Nginx config template
    cat > $APP_DIR/config/nginx.conf << 'EOF'
# Nginx Configuration Template
# Copy to: /etc/nginx/sites-available/app
# Enable: ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/
# Test: sudo nginx -t
# Reload: sudo systemctl reload nginx

server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /uploads {
        alias /home/ubuntu/app/uploads;
        expires 30d;
    }
}
EOF
    
    print_info "Configuration templates created in $APP_DIR/config/"
}

# ------------------------------------
# Verify installations
# ------------------------------------
verify_installations() {
    print_step "Verifying installations..."
    
    # Check Node.js
    if command -v node > /dev/null; then
        print_info "✓ Node.js: $(node -v)"
    fi
    
    # Check Nginx
    if command -v nginx > /dev/null && systemctl is-active --quiet nginx; then
        print_info "✓ Nginx: running"
    fi
    
    # Check MongoDB
    if command -v mongod > /dev/null && systemctl is-active --quiet mongod; then
        print_info "✓ MongoDB: running"
    fi
    
    # Check PM2
    if command -v pm2 > /dev/null; then
        print_info "✓ PM2: $(pm2 --version)"
    fi
    
    # Check directories
    if [ -d "$APP_DIR/logs" ]; then
        print_info "✓ Logs directory: $APP_DIR/logs"
    fi
    
    if [ -d "$APP_DIR/uploads" ]; then
        print_info "✓ Uploads directory: $APP_DIR/uploads"
    fi
}

# ------------------------------------
# Show next steps
# ------------------------------------
show_next_steps() {
    echo ""
    echo "=================================================="
    echo "✅ SETUP COMPLETED SUCCESSFULLY!"
    echo "=================================================="
    echo ""
    echo "📁 Application directory: $APP_DIR"
    echo "📋 Log file: $LOG_FILE"
    echo ""
    echo "📝 NEXT STEPS (Phase 2):"
    echo "1. Copy your application code to $APP_DIR"
    echo "2. Configure environment:"
    echo "   cp $APP_DIR/config/.env.example $APP_DIR/.env"
    echo "   nano $APP_DIR/.env"
    echo ""
    echo "3. Configure Nginx:"
    echo "   sudo cp $APP_DIR/config/nginx.conf /etc/nginx/sites-available/app"
    echo "   sudo ln -s /etc/nginx/sites-available/app /etc/nginx/sites-enabled/"
    echo "   sudo nginx -t"
    echo "   sudo systemctl reload nginx"
    echo ""
    echo "4. Set up domain and SSL:"
    echo "   sudo apt install -y certbot python3-certbot-nginx"
    echo "   sudo certbot --nginx -d your-domain.com"
    echo ""
    echo "5. Start the application:"
    echo "   cd $APP_DIR"
    echo "   pm2 start ecosystem.config.js"
    echo "   pm2 save"
    echo ""
    echo "=================================================="
}

# ------------------------------------
# Main execution
# ------------------------------------
main() {
    echo "=================================================="
    echo "🚀 SERVER SETUP SCRIPT - PHASE 1"
    echo "=================================================="
    echo ""
    
    # Check if running as root (should not)
    if [ "$EUID" -eq 0 ]; then 
        print_error "Please do not run this script as root"
        exit 1
    fi
    
    # Run all steps
    check_system
    update_system
    install_basic_tools
    install_nodejs
    install_nginx
    install_mongodb
    install_pm2
    
    # Create directories and configs
    create_directories
    create_config_templates
    
    # Install project dependencies (if package.json exists)
    if [ -f "package.json" ]; then
        install_project_deps
    else
        print_info "Skipping npm install - no package.json found"
    fi
    
    # Verify and show next steps
    verify_installations
    show_next_steps
}

# Run main function
main