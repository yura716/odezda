#!/bin/bash

# 🚀 Автоматический скрипт установки Odezda AI на VPS
# Использование: curl -fsSL https://raw.githubusercontent.com/username/odezda/main/install_vps.sh | bash

set -e

echo "=========================================="
echo "🚀 Установка Odezda AI на VPS"
echo "=========================================="
echo ""

# Проверка что запущено от root
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Пожалуйста запустите от root: sudo bash install_vps.sh"
    exit 1
fi

# Обновление системы
echo "📦 Обновление системы..."
apt update && apt upgrade -y

# Установка базовых пакетов
echo "📦 Установка базовых пакетов..."
apt install -y curl wget git vim ufw fail2ban unattended-upgrades

# Установка Docker
echo "🐳 Установка Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
else
    echo "✅ Docker уже установлен"
fi

# Установка Docker Compose
echo "🐳 Установка Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    apt install -y docker-compose
else
    echo "✅ Docker Compose уже установлен"
fi

# Настройка Firewall
echo "🔒 Настройка Firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Создание директории
echo "📁 Создание директории проекта..."
mkdir -p /opt/odezda
cd /opt/odezda

# Запрос информации у пользователя
echo ""
echo "=========================================="
echo "⚙️  Настройка"
echo "=========================================="
echo ""

read -p "Введите ваш OpenAI API ключ: " OPENAI_KEY
read -p "Введите ваш NanoBanana API ключ: " NANOBANANA_KEY
read -p "Введите ваш домен (или оставьте пустым для использования IP): " DOMAIN

if [ -z "$DOMAIN" ]; then
    # Получаем внешний IP
    EXTERNAL_IP=$(curl -s ifconfig.me)
    FRONTEND_URL="http://$EXTERNAL_IP"
    BACKEND_URL="http://$EXTERNAL_IP:8000"
    ALLOWED_ORIGINS="http://$EXTERNAL_IP,http://localhost:3000"
else
    FRONTEND_URL="https://$DOMAIN"
    BACKEND_URL="https://$DOMAIN"
    ALLOWED_ORIGINS="https://$DOMAIN,http://$DOMAIN,http://localhost:3000"
fi

echo ""
echo "✅ Конфигурация:"
echo "   Frontend URL: $FRONTEND_URL"
echo "   Backend URL: $BACKEND_URL"
echo ""

# Клонирование или запрос URL репозитория
echo "📥 Получение кода проекта..."
read -p "Введите URL GitHub репозитория (или оставьте пустым для ручной загрузки): " REPO_URL

if [ ! -z "$REPO_URL" ]; then
    git clone "$REPO_URL" /opt/odezda-temp
    mv /opt/odezda-temp/* /opt/odezda/
    rm -rf /opt/odezda-temp
else
    echo ""
    echo "⚠️  Репозиторий не указан!"
    echo ""
    echo "Загрузите код на сервер вручную:"
    echo "  scp -r /path/to/odezda root@$EXTERNAL_IP:/opt/odezda"
    echo ""
    echo "После загрузки запустите скрипт снова"
    exit 1
fi

# Создание .env файлов
echo "⚙️  Создание конфигурационных файлов..."

cat > /opt/odezda/backend/.env << EOF
OPENAI_API_KEY=$OPENAI_KEY
NANOBANANA_API_KEY=$NANOBANANA_KEY
HOST=0.0.0.0
PORT=8000
ALLOWED_ORIGINS=$ALLOWED_ORIGINS
EOF

cat > /opt/odezda/frontend/.env << EOF
REACT_APP_API_URL=$BACKEND_URL
EOF

# Запуск Docker Compose
echo "🚀 Запуск контейнеров..."
cd /opt/odezda
docker-compose up -d --build

# Ожидание запуска
echo "⏳ Ожидание запуска сервисов..."
sleep 10

# Проверка статуса
echo ""
echo "🔍 Проверка статуса..."
docker-compose ps

# Настройка автозапуска
echo "⚙️  Настройка автозапуска..."
cat > /etc/systemd/system/odezda.service << EOF
[Unit]
Description=Odezda AI
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/odezda
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl enable odezda.service

# Настройка SSL (если есть домен)
if [ ! -z "$DOMAIN" ]; then
    echo ""
    read -p "Настроить HTTPS с Let's Encrypt? (y/n): " SETUP_SSL
    
    if [ "$SETUP_SSL" = "y" ]; then
        echo "🔒 Установка Nginx и Certbot..."
        apt install -y nginx certbot python3-certbot-nginx
        
        # Остановка контейнеров временно
        docker-compose down
        
        # Создание конфига Nginx
        cat > /etc/nginx/sites-available/odezda << NGINXEOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
        proxy_read_timeout 300s;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINXEOF
        
        rm -f /etc/nginx/sites-enabled/default
        ln -sf /etc/nginx/sites-available/odezda /etc/nginx/sites-enabled/
        
        nginx -t && systemctl restart nginx
        
        # Изменение портов в docker-compose
        sed -i 's/"80:80"/"3000:80"/g' /opt/odezda/docker-compose.yml
        
        # Получение SSL
        echo "🔐 Получение SSL сертификата..."
        certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos -m admin@$DOMAIN
        
        # Перезапуск контейнеров
        cd /opt/odezda
        docker-compose up -d --build
        
        systemctl restart nginx
        
        echo "✅ HTTPS настроен!"
    fi
fi

# Финальная проверка
echo ""
echo "=========================================="
echo "✅ Установка завершена!"
echo "=========================================="
echo ""
echo "🌐 Ваш сайт доступен по адресу:"
if [ -z "$DOMAIN" ]; then
    echo "   $FRONTEND_URL"
else
    echo "   https://$DOMAIN"
fi
echo ""
echo "📊 Полезные команды:"
echo "   docker-compose logs -f           # Логи"
echo "   docker-compose restart           # Перезапуск"
echo "   docker-compose ps                # Статус"
echo "   docker-compose down              # Остановка"
echo ""
echo "📚 Документация: /opt/odezda/VPS_SETUP.md"
echo ""
echo "🎉 Готово!"
echo ""

