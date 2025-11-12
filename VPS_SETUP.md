# 🖥️ Развертывание на VPS сервере

## 📋 Что вам понадобится:

- ✅ VPS сервер (Hetzner, DigitalOcean, Linode и т.д.)
- ✅ Ubuntu 22.04 (рекомендуется)
- ✅ Минимум 2GB RAM
- ✅ 20GB+ дискового пространства
- ✅ Домен (опционально, но рекомендуется)
- ✅ SSH доступ к серверу

---

## 🚀 Быстрый старт (5 шагов)

### Шаг 1: Подключитесь к серверу

```bash
ssh root@ваш-ip-адрес
```

### Шаг 2: Запустите автоматическую установку

```bash
# Скачайте и запустите скрипт установки
curl -fsSL https://raw.githubusercontent.com/ваш-username/odezda/main/install_vps.sh | bash
```

Или следуйте подробной инструкции ниже 👇

---

## 📝 Подробная инструкция

### Шаг 1: Подключение к серверу

После аренды VPS вы получите:
- IP адрес (например: `123.45.67.89`)
- Root пароль (или SSH ключ)

**Подключитесь:**

```bash
ssh root@123.45.67.89
```

При первом подключении ответьте `yes` на вопрос о fingerprint.

---

### Шаг 2: Обновите систему

```bash
# Обновите пакеты
apt update && apt upgrade -y

# Установите базовые утилиты
apt install -y curl wget git vim ufw
```

---

### Шаг 3: Установите Docker

```bash
# Установите Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Установите Docker Compose
apt install -y docker-compose

# Проверьте установку
docker --version
docker-compose --version
```

**Должно вывести что-то вроде:**
```
Docker version 24.0.7
docker-compose version 1.29.2
```

---

### Шаг 4: Настройте Firewall

```bash
# Разрешите SSH, HTTP, HTTPS
ufw allow 22/tcp    # SSH
ufw allow 80/tcp    # HTTP
ufw allow 443/tcp   # HTTPS

# Включите firewall
ufw --force enable

# Проверьте статус
ufw status
```

---

### Шаг 5: Клонируйте проект

#### Вариант A: Из GitHub (если загрузили)

```bash
cd /opt
git clone https://github.com/ваш-username/odezda.git
cd odezda
```

#### Вариант B: Загрузить с локального компьютера

На вашем Mac:

```bash
# Запакуйте проект
cd /Users/urij/Documents/odezda
tar -czf odezda.tar.gz --exclude=node_modules --exclude=venv --exclude=backend/__pycache__ .

# Загрузите на сервер
scp odezda.tar.gz root@123.45.67.89:/opt/
```

На сервере:

```bash
cd /opt
tar -xzf odezda.tar.gz -C odezda
cd odezda
```

---

### Шаг 6: Настройте переменные окружения

#### Backend (.env)

```bash
cat > backend/.env << 'EOF'
OPENAI_API_KEY=ваш_ключ_openai
NANOBANANA_API_KEY=ваш_ключ_nanobanana
HOST=0.0.0.0
PORT=8000
ALLOWED_ORIGINS=http://ваш-домен.com,https://ваш-домен.com,http://ваш-ip-адрес,http://localhost:3000
EOF
```

**Замените:**
- `ваш_ключ_openai` → ваш OpenAI API ключ
- `ваш_ключ_nanobanana` → ваш NanoBanana API ключ
- `ваш-домен.com` → ваш домен (если есть)
- `ваш-ip-адрес` → IP адрес сервера

#### Frontend (.env)

```bash
cat > frontend/.env << 'EOF'
REACT_APP_API_URL=http://ваш-ip-адрес:8000
EOF
```

**Замените:**
- `ваш-ip-адрес` → IP адрес вашего сервера
- Или используйте домен: `http://ваш-домен.com`

---

### Шаг 7: Запустите через Docker Compose

```bash
# Соберите и запустите контейнеры
docker-compose up -d --build

# Проверьте статус
docker-compose ps
```

**Должно показать:**
```
NAME                COMMAND                  SERVICE             STATUS              PORTS
odezda-backend-1    "uvicorn main:app..."   backend             running             0.0.0.0:8000->8000/tcp
odezda-frontend-1   "nginx -g 'daemon..."   frontend            running             0.0.0.0:80->80/tcp
```

**Проверьте логи:**
```bash
# Все логи
docker-compose logs -f

# Только backend
docker-compose logs -f backend

# Только frontend
docker-compose logs -f frontend
```

---

### Шаг 8: Проверьте что работает

```bash
# Проверьте backend
curl http://localhost:8000

# Должно вернуть: {"message":"Odezda AI API работает!"}

# Проверьте frontend
curl http://localhost:80

# Должно вернуть HTML
```

**Откройте в браузере:**
```
http://ваш-ip-адрес
```

Вы должны увидеть ваш сайт! 🎉

---

## 🌐 Шаг 9: Настройка домена (опционально)

Если у вас есть домен (например `odezda.com`):

### 9.1 Настройте DNS

В панели управления вашего регистратора доменов (Namecheap, GoDaddy и т.д.) добавьте A-записи:

```
Тип    Имя    Значение
A      @      123.45.67.89
A      www    123.45.67.89
```

Где `123.45.67.89` - IP вашего сервера.

### 9.2 Обновите конфигурацию

Обновите `frontend/.env`:
```bash
echo "REACT_APP_API_URL=https://odezda.com" > frontend/.env
```

Обновите `backend/.env`:
```bash
# Добавьте домен в ALLOWED_ORIGINS
ALLOWED_ORIGINS=https://odezda.com,http://odezda.com
```

### 9.3 Перезапустите контейнеры

```bash
docker-compose down
docker-compose up -d --build
```

---

## 🔒 Шаг 10: Настройка HTTPS (Let's Encrypt)

**Важно!** HTTPS нужен для безопасности и для работы с некоторыми API.

### 10.1 Установите Certbot

```bash
apt install -y certbot python3-certbot-nginx
```

### 10.2 Остановите контейнеры (временно)

```bash
docker-compose down
```

### 10.3 Установите Nginx на хосте

```bash
apt install -y nginx
```

### 10.4 Создайте конфиг Nginx

```bash
cat > /etc/nginx/sites-available/odezda << 'EOF'
# Backend API
server {
    listen 80;
    server_name odezda.com www.odezda.com;

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        proxy_read_timeout 300s;
    }

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF
```

### 10.5 Активируйте конфиг

```bash
# Удалите дефолтный конфиг
rm /etc/nginx/sites-enabled/default

# Активируйте новый
ln -s /etc/nginx/sites-available/odezda /etc/nginx/sites-enabled/

# Проверьте конфигурацию
nginx -t

# Перезапустите Nginx
systemctl restart nginx
```

### 10.6 Получите SSL сертификат

```bash
certbot --nginx -d odezda.com -d www.odezda.com
```

Следуйте инструкциям:
1. Введите email
2. Согласитесь с условиями (Y)
3. Выберите опцию 2 (Redirect to HTTPS)

**Certbot автоматически:**
- ✅ Получит бесплатный SSL сертификат
- ✅ Настроит HTTPS
- ✅ Настроит автоматическое обновление

### 10.7 Обновите docker-compose.yml

Измените порты, чтобы не конфликтовали с Nginx:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    ports:
      - "8000:8000"  # Оставляем как есть
    env_file:
      - backend/.env
    volumes:
      - ./backend/uploads:/app/uploads
    restart: unless-stopped

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    ports:
      - "3000:80"  # Изменили на 3000 (внутри контейнера 80)
    depends_on:
      - backend
    restart: unless-stopped
```

### 10.8 Перезапустите всё

```bash
# Запустите контейнеры
cd /opt/odezda
docker-compose up -d --build

# Перезапустите Nginx
systemctl restart nginx
```

### 10.9 Проверьте HTTPS

Откройте в браузере:
```
https://odezda.com
```

Должен работать с зеленым замочком! 🔒✅

---

## 🔄 Автозапуск при перезагрузке

Docker Compose автоматически перезапустит контейнеры благодаря `restart: unless-stopped`.

Проверьте:

```bash
# Перезагрузите сервер
reboot

# Подождите 2-3 минуты, затем подключитесь
ssh root@ваш-ip-адрес

# Проверьте что контейнеры запустились
docker-compose ps
```

---

## 📊 Мониторинг и управление

### Просмотр логов

```bash
# Все логи
docker-compose logs -f

# Последние 100 строк backend
docker-compose logs --tail=100 backend

# Логи Nginx
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log
```

### Перезапуск сервисов

```bash
# Перезапустить всё
docker-compose restart

# Перезапустить только backend
docker-compose restart backend

# Перезапустить только frontend
docker-compose restart frontend
```

### Обновление кода

```bash
cd /opt/odezda

# Получите обновления из Git
git pull

# Пересоберите контейнеры
docker-compose down
docker-compose up -d --build
```

### Остановка сервисов

```bash
# Остановить
docker-compose stop

# Остановить и удалить контейнеры
docker-compose down

# Остановить и удалить всё (включая volumes)
docker-compose down -v
```

---

## 🛡️ Безопасность

### 1. Создайте нового пользователя (не root)

```bash
# Создайте пользователя
adduser odezda

# Добавьте в группу sudo
usermod -aG sudo odezda

# Добавьте в группу docker
usermod -aG docker odezda

# Переключитесь на нового пользователя
su - odezda
```

### 2. Настройте SSH ключи (опционально)

На вашем Mac:

```bash
# Сгенерируйте SSH ключ (если нет)
ssh-keygen -t ed25519

# Скопируйте на сервер
ssh-copy-id odezda@ваш-ip-адрес
```

### 3. Отключите вход по паролю (опционально)

На сервере:

```bash
# Отредактируйте конфиг SSH
sudo nano /etc/ssh/sshd_config

# Измените:
PasswordAuthentication no
PermitRootLogin no

# Перезапустите SSH
sudo systemctl restart sshd
```

### 4. Установите Fail2Ban (защита от брутфорса)

```bash
sudo apt install -y fail2ban

# Создайте конфиг
sudo cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 3600
EOF

# Запустите
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 5. Настройте автоматические обновления

```bash
sudo apt install -y unattended-upgrades

sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 🔍 Диагностика проблем

### Проблема: Сайт не открывается

**Проверьте:**

```bash
# Контейнеры запущены?
docker-compose ps

# Nginx работает?
systemctl status nginx

# Порты открыты?
ss -tulpn | grep -E '80|443|8000|3000'

# Firewall настроен?
ufw status
```

### Проблема: 502 Bad Gateway

**Причины:**
- Backend не запущен
- Неверный proxy_pass в Nginx

**Проверьте:**

```bash
# Backend доступен?
curl http://localhost:8000

# Логи backend
docker-compose logs backend

# Логи Nginx
tail -f /var/log/nginx/error.log
```

### Проблема: CORS ошибки

**Проверьте `backend/.env`:**

```bash
cat backend/.env | grep ALLOWED_ORIGINS

# Должно быть:
# ALLOWED_ORIGINS=https://ваш-домен.com
```

Если неверно, исправьте и перезапустите:

```bash
docker-compose restart backend
```

### Проблема: SSL сертификат не работает

```bash
# Проверьте сертификат
certbot certificates

# Обновите вручную
certbot renew

# Перезапустите Nginx
systemctl restart nginx
```

---

## 📈 Оптимизация производительности

### 1. Увеличьте лимиты памяти Docker

В `docker-compose.yml` добавьте:

```yaml
services:
  backend:
    # ... остальное
    deploy:
      resources:
        limits:
          memory: 1G
        reservations:
          memory: 512M
```

### 2. Настройте кеширование Nginx

В `/etc/nginx/sites-available/odezda` добавьте:

```nginx
# Кеширование статики
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    proxy_pass http://localhost:3000;
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

### 3. Включите gzip сжатие

В `/etc/nginx/nginx.conf`:

```nginx
gzip on;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_types text/plain text/css text/xml text/javascript application/json application/javascript application/xml+rss;
```

---

## 💸 Стоимость

### VPS:
- **Hetzner CX11:** €4.5/мес (2GB RAM, 40GB SSD)
- **DigitalOcean Basic:** $6/мес (1GB RAM, 25GB SSD)
- **Linode Nanode:** $5/мес (1GB RAM, 25GB SSD)

### Домен:
- **`.com`:** ~$10-15/год
- **`.ru`:** ~$5-10/год

### SSL:
- **Let's Encrypt:** Бесплатно!

### API (по использованию):
- **OpenAI:** ~$0.03-0.06 за запрос
- **NanoBanana:** ~$0.02-0.05 за изображение

**Итого:** ~$10-15/мес + API расходы

---

## 📋 Чек-лист развертывания

- [ ] Арендован VPS сервер
- [ ] Подключились по SSH
- [ ] Обновили систему
- [ ] Установили Docker и Docker Compose
- [ ] Настроили firewall
- [ ] Клонировали проект
- [ ] Создали `.env` файлы с API ключами
- [ ] Запустили через `docker-compose up -d`
- [ ] Проверили что сайт работает по IP
- [ ] (Опционально) Настроили домен
- [ ] (Опционально) Настроили HTTPS
- [ ] (Опционально) Настроили автозапуск
- [ ] Проверили логи
- [ ] Протестировали функционал

---

## 🎉 Готово!

Ваш сайт теперь доступен 24/7 по адресу:

- **По IP:** `http://ваш-ip-адрес`
- **По домену:** `https://ваш-домен.com`

**Следующие шаги:**
1. Протестируйте все функции
2. Настройте мониторинг
3. Добавьте rate limiting
4. Следите за расходами на API
5. Делайте регулярные бэкапы

**Удачи!** 🚀✨

