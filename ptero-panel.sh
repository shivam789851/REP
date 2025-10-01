#!/bin/bash

clear

# Colors
RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
YEL='\033[1;33m'
NC='\033[0m' # No Color

# Banner
echo -e "${YEL}"
cat << "EOF"
 /$$$$$$$$       /$$     /$$       /$$   /$$       /$$$$$$$$       /$$   /$$
|_____ $$       |  $$   /$$/      | $$$ | $$      | $$_____/      | $$  / $$
     /$$/        \  $$ /$$/       | $$$$| $$      | $$            |  $$/ $$/
    /$$/          \  $$$$/        | $$ $$ $$      | $$$$$          \  $$$$/ 
   /$$/            \  $$/         | $$  $$$$      | $$__/           >$$  $$ 
  /$$/              | $$          | $$\  $$$      | $$             /$$/\  $$
 /$$$$$$$$          | $$          | $$ \  $$      | $$$$$$$$      | $$  \ $$
|________/          |__/          |__/  \__/      |________/      |__/  |__/
EOF
echo -e "${NC}"

# Subscription Prompt
echo -e "${GRN}🔥 Please Subscribe \n${NC}"

for i in {1..3}; do
  echo -ne "${CYN}Subscribing To zyexcode"
  for dot in {1..3}; do
    echo -n "."
    sleep 0.3
  done
  echo -ne "\r\033[K"  # Clear line for smooth animation
done

echo -e "${GRN}✅ Thanks for Subscribing! If Not, Do It Now 🚀${NC}\n"
sleep 1

echo -e "${YEL}X-> Installing Docker Compose...${NC}"
apt update && apt upgrade -y
apt install docker-compose -y

echo -e "${CYN}X-> Setting up Pterodactyl Panel directories...${NC}"
mkdir -p pterodactyl/panel
cd pterodactyl/panel || exit

echo -e "${CYN}X-> Writing docker-compose.yml...${NC}"
cat <<EOF > docker-compose.yml
version: '3.8'
x-common:
  database:
    &db-environment
    MYSQL_PASSWORD: &db-password "CHANGE_ME"
    MYSQL_ROOT_PASSWORD: "CHANGE_ME_TOO"
  panel:
    &panel-environment
    APP_URL: "https://pterodactyl.example.com"
    APP_TIMEZONE: "UTC"
    APP_SERVICE_AUTHOR: "noreply@example.com"
    TRUSTED_PROXIES: "*"
    # LE_EMAIL: ""
  mail:
    &mail-environment
    MAIL_FROM: "noreply@example.com"
    MAIL_DRIVER: "smtp"
    MAIL_HOST: "mail"
    MAIL_PORT: "1025"
    MAIL_USERNAME: ""
    MAIL_PASSWORD: ""
    MAIL_ENCRYPTION: "true"

services:
  database:
    image: mariadb:10.5
    restart: always
    command: --default-authentication-plugin=mysql_native_password
    volumes:
      - "./data/database:/var/lib/mysql"
    environment:
      <<: *db-environment
      MYSQL_DATABASE: "panel"
      MYSQL_USER: "pterodactyl"

  cache:
    image: redis:alpine
    restart: always

  panel:
    image: ghcr.io/pterodactyl/panel:latest
    restart: always
    ports:
      - "80:80"
      - "443:443"
    links:
      - database
      - cache
    volumes:
      - "./data/var:/app/var"
      - "./data/nginx:/etc/nginx/http.d"
      - "./data/certs:/etc/letsencrypt"
      - "./data/logs:/app/storage/logs"
    environment:
      <<: [*panel-environment, *mail-environment]
      DB_PASSWORD: *db-password
      APP_ENV: "production"
      APP_ENVIRONMENT_ONLY: "false"
      CACHE_DRIVER: "redis"
      SESSION_DRIVER: "redis"
      QUEUE_DRIVER: "redis"
      REDIS_HOST: "cache"
      DB_HOST: "database"
      DB_PORT: "3306"

networks:
  default:
    ipam:
      config:
        - subnet: 172.20.0.0/16

EOF

echo -e "${CYN}X-> Creating data directories...${NC}"
mkdir -p ./data/{database,var,nginx,certs,logs}

echo -e "${GRN}X-> Starting Pterodactyl containers...${NC}"
docker-compose up -d

echo -e "${GRN}X-> Creating Admin User...${NC}"
docker-compose run --rm panel php artisan p:user:make

echo -e "${YEL}✅ Panel is installed! Enjoy now${NC}"


