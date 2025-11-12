# 🏠 Использование Mac как домашнего сервера

## 📖 Обзор

Вы можете использовать свой Mac как постоянный сервер для размещения сайта.

**Принцип работы:**
```
Интернет
    ↓
Ваш роутер (проброс портов)
    ↓
Ваш Mac (сервер)
```

---

## ⚠️ Важно понимать

### ✅ Преимущества:
- 💰 Бесплатно (только электричество)
- 🎛️ Полный контроль
- 💾 Неограниченное хранилище
- 🔧 Можете настроить всё как хотите

### ❌ Недостатки:
- 🔌 Mac должен быть **всегда включен**
- 💡 Расход электричества (~$5-10/мес)
- 🌐 Нужен хороший интернет (стабильный upload)
- 🏠 Зависит от вашего провайдера
- 🔒 Безопасность - ваша ответственность
- 📍 Если динамический IP - нужен DDNS
- 🔥 Mac может греться и шуметь

---

## 🚀 Быстрый старт (5 шагов)

### Шаг 1: Настройте статический локальный IP

Чтобы роутер всегда знал где ваш Mac:

1. Откройте **System Settings** → **Network**
2. Выберите активное подключение (Wi-Fi или Ethernet)
3. Нажмите **Details**
4. Перейдите на вкладку **TCP/IP**
5. Запишите текущий IP (например: `192.168.1.100`)
6. Измените **Configure IPv4** на **Manually**
7. Введите:
   - **IP Address:** `192.168.1.100` (ваш текущий IP)
   - **Subnet Mask:** `255.255.255.0`
   - **Router:** `192.168.1.1` (IP вашего роутера)
8. Нажмите **OK** → **Apply**

**Или через терминал:**

```bash
# Узнайте ваш текущий IP
ifconfig | grep "inet "

# Узнайте IP роутера
netstat -nr | grep default

# Запомните эти адреса для настройки
```

---

### Шаг 2: Проброс портов на роутере (Port Forwarding)

Это самая важная часть! Нужно настроить роутер чтобы пропускать трафик на ваш Mac.

#### Универсальная инструкция:

1. Откройте веб-интерфейс роутера:
   - Обычно: `http://192.168.1.1` или `http://192.168.0.1`
   - Или адрес из шага 1 (Router)

2. Войдите:
   - Логин/пароль обычно на наклейке роутера
   - Или admin/admin, admin/password

3. Найдите раздел:
   - **Port Forwarding** / **Virtual Server**
   - **NAT** / **Переадресация портов**
   - В разных роутерах называется по-разному

4. Создайте правила:

   **Правило 1 - HTTP:**
   - External Port: `80`
   - Internal Port: `80`
   - Internal IP: `192.168.1.100` (ваш Mac)
   - Protocol: `TCP`
   
   **Правило 2 - HTTPS:**
   - External Port: `443`
   - Internal Port: `443`
   - Internal IP: `192.168.1.100`
   - Protocol: `TCP`
   
   **Правило 3 - Backend (опционально):**
   - External Port: `8000`
   - Internal Port: `8000`
   - Internal IP: `192.168.1.100`
   - Protocol: `TCP`

5. Сохраните и перезагрузите роутер

#### Примеры для популярных роутеров:

**TP-Link:**
- Forwarding → Virtual Servers → Add New

**D-Link:**
- Advanced → Port Forwarding

**ASUS:**
- WAN → Virtual Server/Port Forwarding

**Keenetic:**
- Домашняя сеть → Серверы → Добавить правило

---

### Шаг 3: Узнайте ваш внешний IP адрес

```bash
# В терминале
curl ifconfig.me

# Или откройте в браузере
# https://whatismyipaddress.com
```

Запишите этот IP! Это адрес вашего сайта: `http://123.45.67.89`

**⚠️ Если IP меняется:**

У многих провайдеров динамический IP (меняется при переподключении). В этом случае нужен **Dynamic DNS** (см. Шаг 4).

---

### Шаг 4: Настройте Dynamic DNS (если IP меняется)

Dynamic DNS дает вам постоянный домен даже если IP меняется.

#### Бесплатные DDNS сервисы:

**1. No-IP (Рекомендую)**

1. Зарегистрируйтесь на https://www.noip.com
2. Создайте hostname (например: `mysite.ddns.net`)
3. Скачайте клиент для Mac: https://www.noip.com/download
4. Установите и запустите
5. Войдите в аккаунт
6. Клиент автоматически будет обновлять IP

**2. DuckDNS**

1. Зарегистрируйтесь на https://www.duckdns.org
2. Создайте subdomain
3. Установите клиент:

```bash
# Создайте скрипт
mkdir ~/duckdns
cd ~/duckdns
cat > duck.sh << 'EOF'
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=yoursubdomain&token=yourtoken&ip=" | curl -k -o ~/duckdns/duck.log -K -
EOF

chmod +x duck.sh

# Добавьте в cron (обновление каждые 5 минут)
crontab -e
# Добавьте строку:
*/5 * * * * ~/duckdns/duck.sh >/dev/null 2>&1
```

**3. Cloudflare (если есть домен)**

Самый надежный вариант:

1. Зарегистрируйте домен
2. Перенесите DNS на Cloudflare (бесплатно)
3. Используйте скрипт для автообновления IP

---

### Шаг 5: Настройте Mac для работы как сервер

#### 5.1 Отключите спящий режим

```bash
# Запретить Mac засыпать
sudo pmset -a disablesleep 1

# Отключить засыпание диска
sudo pmset -a disksleep 0

# Отключить засыпание дисплея (экран можно выключать)
sudo pmset -a displaysleep 10

# Проверьте настройки
pmset -g
```

**Или через System Settings:**
1. **Battery** → **Power Adapter**
2. Установите **Prevent automatic sleeping** when display is off
3. Установите **Wake for network access**

#### 5.2 Настройте автозапуск приложения

**Создайте Launch Agent для автозапуска:**

```bash
# Создайте файл запуска backend
cat > ~/Library/LaunchAgents/com.odezda.backend.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.odezda.backend</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/urij/Documents/odezda/backend/venv/bin/python</string>
        <string>/Users/urij/Documents/odezda/backend/main.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>WorkingDirectory</key>
    <string>/Users/urij/Documents/odezda/backend</string>
    <key>StandardOutPath</key>
    <string>/tmp/odezda-backend.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/odezda-backend-error.log</string>
</dict>
</plist>
EOF

# Загрузите Launch Agent
launchctl load ~/Library/LaunchAgents/com.odezda.backend.plist
```

**Для frontend (через PM2 - лучше):**

```bash
# Установите PM2
npm install -g pm2

# Запустите frontend
cd /Users/urij/Documents/odezda/frontend
pm2 start npm --name "odezda-frontend" -- start

# Сохраните конфигурацию
pm2 save

# Настройте автозапуск
pm2 startup
# Выполните команду которую выдаст pm2
```

#### 5.3 Настройте firewall macOS

```bash
# Включите firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on

# Разрешите входящие подключения для Python
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Users/urij/Documents/odezda/backend/venv/bin/python
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /Users/urij/Documents/odezda/backend/venv/bin/python

# Разрешите Node.js
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add $(which node)
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp $(which node)
```

---

## 🌐 Шаг 6: Настройте Nginx (рекомендуется)

Nginx будет выступать как reverse proxy и обрабатывать SSL.

### Установите Nginx

```bash
brew install nginx
```

### Настройте конфигурацию

```bash
# Создайте конфиг
cat > /usr/local/etc/nginx/servers/odezda.conf << 'EOF'
server {
    listen 80;
    server_name _;  # Или ваш домен

    # Backend API
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

    # Frontend
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

# Проверьте конфигурацию
nginx -t

# Запустите Nginx
brew services start nginx
```

### Настройте автозапуск Nginx

```bash
# Nginx автоматически запустится через brew services
brew services list

# Должно показать:
# nginx started
```

---

## 🔒 Шаг 7: Настройте HTTPS (опционально)

Если у вас есть домен, настройте бесплатный SSL от Let's Encrypt.

### Установите Certbot

```bash
brew install certbot
```

### Получите сертификат

```bash
# Остановите Nginx временно
brew services stop nginx

# Получите сертификат
sudo certbot certonly --standalone -d ваш-домен.com

# Запустите Nginx обратно
brew services start nginx
```

### Обновите конфиг Nginx для HTTPS

```bash
cat > /usr/local/etc/nginx/servers/odezda.conf << 'EOF'
# Редирект HTTP → HTTPS
server {
    listen 80;
    server_name ваш-домен.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name ваш-домен.com;

    ssl_certificate /etc/letsencrypt/live/ваш-домен.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/ваш-домен.com/privkey.pem;

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
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

nginx -t && brew services restart nginx
```

### Настройте автообновление сертификата

```bash
# Добавьте в cron
crontab -e

# Добавьте строку (обновление каждый понедельник в 3 утра):
0 3 * * 1 /usr/local/bin/certbot renew --quiet && /usr/local/bin/brew services restart nginx
```

---

## 📊 Управление сервером

### Просмотр логов

```bash
# Backend логи
tail -f /tmp/odezda-backend.log

# Frontend логи (PM2)
pm2 logs odezda-frontend

# Nginx логи
tail -f /usr/local/var/log/nginx/access.log
tail -f /usr/local/var/log/nginx/error.log
```

### Управление сервисами

```bash
# Backend (Launch Agent)
launchctl unload ~/Library/LaunchAgents/com.odezda.backend.plist  # Остановить
launchctl load ~/Library/LaunchAgents/com.odezda.backend.plist    # Запустить

# Frontend (PM2)
pm2 stop odezda-frontend
pm2 start odezda-frontend
pm2 restart odezda-frontend

# Nginx
brew services stop nginx
brew services start nginx
brew services restart nginx
```

### Проверка статуса

```bash
# Проверьте что порты открыты
lsof -i :80   # Nginx
lsof -i :3000 # Frontend
lsof -i :8000 # Backend

# Проверьте процессы
ps aux | grep python  # Backend
pm2 list                # Frontend
brew services list      # Nginx
```

---

## 🔒 Безопасность

### ⚠️ Риски домашнего сервера:

1. **Ваш домашний IP виден всем** - можно определить ваше местоположение
2. **Прямой доступ в вашу сеть** - если есть уязвимости
3. **DDoS атаки** - могут "положить" ваш интернет
4. **Взлом** - если не следить за безопасностью

### 🛡️ Как защититься:

#### 1. Используйте Cloudflare (настоятельно рекомендую!)

Cloudflare спрячет ваш реальный IP и защитит от атак:

1. Зарегистрируйте домен
2. Перенесите DNS на Cloudflare (бесплатно)
3. Включите proxy (оранжевое облачко)
4. Ваш реальный IP будет скрыт!

#### 2. Настройте rate limiting

Добавьте в `backend/main.py` (см. PUBLIC_ACCESS.md)

#### 3. Мониторьте логи

```bash
# Установите fail2ban (защита от брутфорса)
# Для macOS используйте альтернативы или мониторьте вручную

# Смотрите подозрительную активность
tail -f /usr/local/var/log/nginx/access.log | grep -v "200"
```

#### 4. Регулярно обновляйте

```bash
# Обновляйте систему
softwareupdate -l
softwareupdate -i -a

# Обновляйте Homebrew пакеты
brew update && brew upgrade

# Обновляйте Python зависимости
cd /Users/urij/Documents/odezda/backend
source venv/bin/activate
pip install --upgrade -r requirements.txt
```

---

## 💡 Оптимизация производительности

### 1. Используйте SSD

Если возможно, разместите проект на SSD для быстрой работы.

### 2. Увеличьте лимиты

```bash
# Увеличьте лимит открытых файлов
echo "kern.maxfiles=65536" | sudo tee -a /etc/sysctl.conf
echo "kern.maxfilesperproc=65536" | sudo tee -a /etc/sysctl.conf
```

### 3. Настройте кеширование в Nginx

Добавьте в конфиг:

```nginx
# Кеш для статики
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}
```

---

## 💸 Стоимость

### Электричество:
- **MacBook:** ~30-50W при работе
- **$0.15/kWh** (средняя цена в США)
- **~$5-8/месяц** за электричество

### Интернет:
- Ваш обычный тариф (без дополнительных расходов)
- Но следите за трафиком!

### API:
- OpenAI + NanoBanana по использованию

**Итого:** ~$5-10/мес (электричество) + API costs

---

## ⚡ Энергоэффективность

### Снизьте энергопотребление:

```bash
# Выключите дисплей когда не нужен
pmset displaysleep 5

# Отключите ненужные службы
# System Settings → General → Login Items
# Отключите всё что не нужно

# Закройте лишние приложения
# Оставьте только backend, frontend, nginx
```

### Используйте Mac Mini

Если планируете постоянный сервер - Mac Mini идеален:
- Тихий
- Энергоэффективный (~10-20W)
- Компактный
- Можно спрятать

---

## 🔍 Проверка что всё работает

### 1. Локально

```bash
# Backend
curl http://localhost:8000
# Должно вернуть: {"message":"Odezda AI API работает!"}

# Frontend
curl http://localhost:3000
# Должно вернуть HTML

# Nginx
curl http://localhost:80
# Должно показать сайт
```

### 2. Из внешней сети

```bash
# На другом устройстве (не в вашей сети)
curl http://ваш-внешний-ip

# Или откройте в браузере:
http://ваш-внешний-ip
```

### 3. Проверка портов онлайн

Откройте: https://www.yougetsignal.com/tools/open-ports/

Введите ваш IP и порт 80 - должен быть **open**.

---

## 📋 Чек-лист настройки

- [ ] Настроен статический локальный IP
- [ ] Пробросили порты на роутере (80, 443)
- [ ] Узнали внешний IP адрес
- [ ] (Опционально) Настроили Dynamic DNS
- [ ] Отключили спящий режим Mac
- [ ] Настроили автозапуск backend
- [ ] Настроили автозапуск frontend (PM2)
- [ ] Установили и настроили Nginx
- [ ] Настроили firewall macOS
- [ ] (Опционально) Настроили HTTPS
- [ ] Проверили доступность снаружи
- [ ] Настроили rate limiting
- [ ] Настроили мониторинг логов

---

## 🆘 Решение проблем

### Сайт не доступен снаружи

**Проверьте:**

1. **Порты пробросили?**
   ```bash
   # На другом устройстве
   telnet ваш-внешний-ip 80
   ```

2. **Backend и Frontend запущены?**
   ```bash
   lsof -i :8000
   lsof -i :3000
   ```

3. **Nginx работает?**
   ```bash
   brew services list | grep nginx
   ```

4. **Firewall не блокирует?**
   ```bash
   sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate
   ```

### Mac засыпает

```bash
# Проверьте настройки
pmset -g

# Убедитесь что:
# sleep 0
# disksleep 0
```

### Высокая нагрузка

```bash
# Проверьте процессы
top

# Ограничьте количество worker'ов
# В backend/main.py используйте 1 worker
# uvicorn main:app --workers 1
```

---

## 🎯 Альтернативы

Если домашний сервер не подходит, рассмотрите:

1. **ngrok/Cloudflare Tunnel** - временный доступ ([PUBLIC_ACCESS.md](PUBLIC_ACCESS.md))
2. **VPS сервер** - профессиональное решение ([VPS_SETUP.md](VPS_SETUP.md))
3. **PaaS** - Railway, Render, Vercel ([DEPLOYMENT.md](DEPLOYMENT.md))

---

## 📚 Полезные ссылки

- No-IP DDNS: https://www.noip.com
- DuckDNS: https://www.duckdns.org
- Cloudflare: https://www.cloudflare.com
- Let's Encrypt: https://letsencrypt.org
- Port forwarding guide: https://portforward.com

---

## 🎉 Готово!

Ваш Mac теперь работает как сервер!

**Адрес сайта:**
- По IP: `http://ваш-внешний-ip`
- По домену: `http://ваш-домен.com`
- По DDNS: `http://yourname.ddns.net`

**Удачи!** 🚀✨

