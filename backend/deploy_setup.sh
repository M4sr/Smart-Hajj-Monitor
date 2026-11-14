#!/bin/bash
# ==============================================================================
# Smart Hajj Monitor - VPS Backend Automatic Setup Script
# Recommended OS: Ubuntu 22.04 LTS or 24.04 LTS
# Run this script with sudo/root privileges.
# ==============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# ANSI Color Codes for beautiful output formatting
GREEN='\033[0;32m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
RED='\033[0;31m'

echo -e "${GREEN}==================================================================${NC}"
echo -e "${GREEN}   Memulai Setup Otomatisasi Backend Smart Hajj Monitor di VPS   ${NC}"
echo -e "${GREEN}==================================================================${NC}"

# 1. Update system package index
echo -e "\n${YELLOW}[1/6] Memperbarui package list sistem...${NC}"
sudo apt update -y

# 2. Install required system packages
echo -e "\n${YELLOW}[2/6] Menginstal dependensi sistem (Python, Nginx, Git, Certbot)...${NC}"
sudo apt install -y python3 python3-pip python3-venv python3-dev \
                    mysql-client default-libmysqlclient-dev build-essential \
                    nginx certbot python3-certbot-nginx git curl

# 3. Create app directory if not exists
APP_DIR="/www/wwwroot/app-haji-monitoring.my.id"
echo -e "\n${YELLOW}[3/6] Mempersiapkan direktori aplikasi di ${APP_DIR}...${NC}"
if [ ! -d "$APP_DIR" ]; then
    sudo mkdir -p "$APP_DIR"
    sudo chown -R $USER:$USER "$APP_DIR"
fi

# 4. Copy backend files (assuming files are loaded/cloned to APP_DIR)
# If running this script inside the application folder, we don't need to copy
CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ "$CURRENT_DIR" != "$APP_DIR" ]; then
    echo -e "${YELLOW}Menyalin berkas ke direktori aplikasi ${APP_DIR}...${NC}"
    sudo cp -r "$CURRENT_DIR"/* "$APP_DIR/"
    sudo chown -R $USER:$USER "$APP_DIR"
fi

# 5. Create and configure Python Virtual Environment
echo -e "\n${YELLOW}[4/6] Membuat Python Virtual Environment (venv)...${NC}"
cd "$APP_DIR"
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

echo -e "${YELLOW}Mengaktifkan venv dan menginstal dependensi Python dari requirements.txt...${NC}"
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# 6. Setup ownership & permissions for security
echo -e "\n${YELLOW}[5/6] Mengatur hak akses dan izin direktori untuk Nginx...${NC}"
sudo chown -R www-data:www-data "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"

echo -e "\n${GREEN}[6/6] Setup otomatisasi selesai dilakukan!${NC}"
echo -e "${GREEN}==================================================================${NC}"
echo -e "${YELLOW}Langkah Selanjutnya:${NC}"
echo -e "1. Konfigurasikan database MySQL Anda via aaPanel (menu Databases)."
echo -e "2. Buat berkas '.env' di folder '$APP_DIR/' dengan data kredensial database Anda:"
echo -e "   nano $APP_DIR/.env"
echo -e "3. Salin berkas 'smarthajj.service' ke systemd dan aktifkan:"
echo -e "   sudo cp $APP_DIR/smarthajj.service /etc/systemd/system/"
echo -e "   sudo systemctl daemon-reload && sudo systemctl enable smarthajj && sudo systemctl start smarthajj"
echo -e "4. Konfigurasi Reverse Proxy & SSL via aaPanel (menu Website -> Reverse Proxy & SSL)."
echo -e "${GREEN}==================================================================${NC}"
