#!/bin/bash

# ============================================
# Setup Script for Node.js Web Application
# ============================================

echo "===== STARTING SETUP ====="

# -------------------------------
# 1. Update system packages
# -------------------------------
echo "[1/6] Updating system..."
sudo apt update -y && sudo apt upgrade -y

# -------------------------------
# 2. Install required tools
# -------------------------------
echo "[2/6] Installing basic tools..."
sudo apt install -y curl git build-essential

# -------------------------------
# 3. Install Node.js (v20 LTS)
# -------------------------------
echo "[3/6] Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"

# -------------------------------
# 4. Install project dependencies
# -------------------------------
echo "[4/6] Installing project dependencies..."
npm install

# -------------------------------
# 5. Setup application folders
# -------------------------------
echo "[5/6] Creating folders..."

mkdir -p uploads
mkdir -p logs

# Set permissions
chmod -R 755 uploads logs

# -------------------------------
# 6. Install PM2 (process manager)
# -------------------------------
echo "[6/6] Installing PM2..."
sudo npm install -g pm2

# -------------------------------
# DONE
# -------------------------------
echo "===== SETUP COMPLETED SUCCESSFULLY ====="