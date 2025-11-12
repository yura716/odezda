# 🇷🇺 Развертывание на Beget

## 📖 Обзор

Beget - российский хостинг-провайдер с поддержкой Python и Node.js приложений.

**Что понадобится:**
- Тариф Beget (от ₽200/мес)
- Домен (можно зарегистрировать на Beget)
- SSH доступ
- OpenAI и NanoBanana API ключи

---

## 💰 Рекомендуемый тариф

**Минимум:**
- **"Старт"** - ₽200/мес
  - 2GB место
  - Поддержка Python/Node.js
  - SSH доступ
  - SSL сертификат (бесплатно)

**Оптимально:**
- **"Хостинг M"** - ₽400/мес
  - 10GB место
  - Больше ресурсов
  - Лучше для нагрузок

Заказать: https://beget.com

---

## 🚀 Быстрый старт

### Шаг 1: Зарегистрируйтесь на Beget

1. Перейдите на https://beget.com
2. Выберите тариф
3. Зарегистрируйтесь и оплатите
4. Получите доступы на email:
   - Адрес панели управления
   - Логин/пароль
   - SSH доступы

---

### Шаг 2: Настройте домен

#### Если у вас уже есть домен:

1. В панели управления доменом измените NS-серверы на:
   ```
   ns1.beget.com
   ns2.beget.com
   ```

2. В панели Beget добавьте домен:
   - **Сайты** → **Добавить домен**
   - Введите ваш домен
   - Дождитесь привязки (до 24 часов)

#### Если нет домена:

1. Зарегистрируйте на Beget:
   - **Домены** → **Регистрация домена**
   - Выберите `.ru`, `.com` и т.д.
   - Оплатите (~₽200-500/год)

---

### Шаг 3: Подключитесь по SSH

Вы получили SSH доступы в письме от Beget:
```
Хост: ваш-логин.beget.tech
Порт: 22
Логин: ваш-логин
Пароль: ваш-пароль
```

**Подключитесь:**
```bash
ssh ваш-логин@ваш-логин.beget.tech
```

При первом подключении ответьте `yes`.

---

### Шаг 4: Загрузите проект

#### Вариант A: Через Git (рекомендуется)

На сервере Beget:

```bash
# Перейдите в домашнюю директорию
cd ~

# Клонируйте проект
git clone https://github.com/ваш-username/odezda.git

# Или если не использовали Git:
mkdir odezda
cd odezda
```

#### Вариант B: Через FTP/SFTP

На вашем Mac:

```bash
# Запакуйте проект
cd /Users/urij/Documents/odezda
tar -czf odezda.tar.gz \
  --exclude=node_modules \
  --exclude=venv \
  --exclude=backend/__pycache__ \
  .

# Загрузите через SFTP
sftp ваш-логин@ваш-логин.beget.tech
put odezda.tar.gz
quit
```

На сервере Beget:

```bash
# Распакуйте
tar -xzf odezda.tar.gz -C ~/odezda
cd ~/odezda
```

---

### Шаг 5: Настройка Backend (Python)

#### 5.1 Создайте виртуальное окружение

```bash
cd ~/odezda/backend

# Создайте venv
python3.9 -m venv venv

# Активируйте
source venv/bin/activate

# Установите зависимости
pip install --upgrade pip
pip install -r requirements.txt
```

**⚠️ Важно:** На Beget может не быть последней версии Python. Проверьте:
```bash
python3 --version
```

Если версия < 3.9, используйте доступную или обратитесь в поддержку.

#### 5.2 Создайте .env файл

```bash
cat > ~/odezda/backend/.env << 'EOF'
OPENAI_API_KEY=ваш_ключ_openai
NANOBANANA_API_KEY=ваш_ключ_nanobanana
HOST=0.0.0.0
PORT=8000
ALLOWED_ORIGINS=https://ваш-домен.ru,http://ваш-домен.ru
EOF
```

**Замените:**
- `ваш_ключ_openai` - ваш OpenAI API ключ
- `ваш_ключ_nanobanana` - ваш NanoBanana API ключ  
- `ваш-домен.ru` - ваш домен

#### 5.3 Настройте Passenger для Python

Beget использует Passenger для запуска Python приложений.

Создайте `passenger_wsgi.py`:

```bash
cat > ~/odezda/backend/passenger_wsgi.py << 'EOF'
#!/usr/bin/env python
import sys
import os

# Путь к проекту
INTERP = os.path.join(os.environ['HOME'], 'odezda', 'backend', 'venv', 'bin', 'python')
if sys.executable != INTERP:
    os.execl(INTERP, INTERP, *sys.argv)

# Добавляем путь к проекту
sys.path.insert(0, os.path.join(os.environ['HOME'], 'odezda', 'backend'))

# Загружаем .env
from dotenv import load_dotenv
load_dotenv()

# Импортируем приложение FastAPI
from main import app as application
EOF

chmod +x ~/odezda/backend/passenger_wsgi.py
```

#### 5.4 Создайте .htaccess для backend

```bash
cat > ~/odezda/backend/.htaccess << 'EOF'
PassengerEnabled on
PassengerAppEnv production
PassengerAppType wsgi
PassengerStartupFile passenger_wsgi.py
PassengerPython /home/ваш-логин/odezda/backend/venv/bin/python

RewriteEngine On
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*)$ passenger_wsgi.py [L]
EOF
```

**Замените** `ваш-логин` на ваш логин Beget!

---

### Шаг 6: Настройка Frontend (React)

#### 6.1 Соберите production версию

На вашем **локальном Mac** (не на сервере!):

```bash
cd /Users/urij/Documents/odezda/frontend

# Создайте .env для production
cat > .env.production << 'EOF'
REACT_APP_API_URL=https://ваш-домен.ru/api
EOF

# Соберите production build
npm run build
```

Это создаст папку `build/` со статическими файлами.

#### 6.2 Загрузите build на сервер

```bash
# Запакуйте
cd /Users/urij/Documents/odezda/frontend
tar -czf build.tar.gz build/

# Загрузите на сервер
scp build.tar.gz ваш-логин@ваш-логин.beget.tech:~/odezda/frontend/

# На сервере распакуйте
ssh ваш-логин@ваш-логин.beget.tech
cd ~/odezda/frontend
tar -xzf build.tar.gz
```

---

### Шаг 7: Настройка в панели Beget

#### 7.1 Настройте поддомен для backend

1. Войдите в панель управления Beget
2. **Сайты** → **Добавить поддомен**
3. Создайте: `api.ваш-домен.ru`
4. Корневая директория: `/home/ваш-логин/odezda/backend`

#### 7.2 Настройте основной домен для frontend

1. **Сайты** → выберите ваш домен
2. Корневая директория: `/home/ваш-логин/odezda/frontend/build`

#### 7.3 Включите SSL

1. В панели Beget: **Сайты** → выберите домен
2. **SSL** → **Let's Encrypt**
3. Нажмите **Получить сертификат**
4. Подождите 5-10 минут

---

### Шаг 8: Настройте маршрутизацию

#### 8.1 .htaccess для frontend

```bash
cat > ~/odezda/frontend/build/.htaccess << 'EOF'
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteRule . /index.html [L]
</IfModule>

# Gzip compression
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
</IfModule>

# Browser caching
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/jpg "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
  ExpiresByType image/gif "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType text/css "access plus 1 month"
  ExpiresByType application/javascript "access plus 1 month"
</IfModule>
EOF
```

#### 8.2 Nginx конфиг (если используется)

В некоторых случаях Beget использует Nginx. Создайте файл конфигурации:

```bash
cat > ~/odezda/.nginx.conf << 'EOF'
location /api {
    proxy_pass http://127.0.0.1:8000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_cache_bypass $http_upgrade;
    proxy_read_timeout 300s;
}
EOF
```

---

## ✅ Проверка

### Проверьте backend:

```bash
# На сервере
curl http://localhost:8000
# Должно вернуть: {"message":"Odezda AI API работает!"}
```

### Проверьте в браузере:

```
https://ваш-домен.ru
```

Должен открыться сайт! 🎉

---

## 🔧 Управление через cron (автозапуск)

Beget может перезапускать процессы. Настройте cron для автозапуска:

```bash
# Откройте crontab
crontab -e

# Добавьте (проверка и перезапуск каждые 5 минут):
*/5 * * * * cd ~/odezda/backend && source venv/bin/activate && python -c "import requests; requests.get('http://localhost:8000')" || (cd ~/odezda/backend && source venv/bin/activate && nohup python main.py &)
```

---

## 📊 Альтернативная схема: Backend на отдельном порту

Если Passenger не работает, запустите backend на отдельном порту:

### 1. Запустите backend через systemd (если доступен)

```bash
cat > ~/start_backend.sh << 'EOF'
#!/bin/bash
cd ~/odezda/backend
source venv/bin/activate
python main.py
EOF

chmod +x ~/start_backend.sh
```

### 2. Добавьте в cron для автозапуска

```bash
crontab -e

# Добавьте:
@reboot ~/start_backend.sh
```

### 3. Настройте проксирование в .htaccess основного домена

```bash
cat > ~/ваш-домен.ru/.htaccess << 'EOF'
RewriteEngine On

# Проксирование API запросов на backend
RewriteCond %{REQUEST_URI} ^/api
RewriteRule ^api/(.*)$ http://localhost:8000/api/$1 [P,L]

# Все остальное на frontend
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.html [L]
EOF
```

---

## 🔒 Безопасность

### 1. Защитите .env файл

```bash
cat > ~/odezda/backend/.htaccess << 'EOF'
<Files ".env">
    Order allow,deny
    Deny from all
</Files>
EOF
```

### 2. Ограничьте доступ к uploads

```bash
cat > ~/odezda/backend/uploads/.htaccess << 'EOF'
Options -Indexes
<FilesMatch "\.(jpg|jpeg|png|gif)$">
    Order allow,deny
    Allow from all
</FilesMatch>
EOF
```

### 3. Настройте rate limiting

Добавьте в `backend/main.py` (см. PUBLIC_ACCESS.md)

---

## 📊 Мониторинг

### Логи на Beget:

```bash
# Логи ошибок
tail -f ~/logs/error.log

# Логи доступа
tail -f ~/logs/access.log

# Логи Python приложения
tail -f ~/odezda/backend/logs/app.log
```

### Создайте систему логирования:

```python
# В backend/main.py добавьте:
import logging

logging.basicConfig(
    filename='logs/app.log',
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
```

---

## 💸 Стоимость

### Beget хостинг:
- **Старт:** ₽200/мес
- **Хостинг M:** ₽400/мес

### Домен:
- **`.ru`:** ₽200-300/год
- **`.com`:** ₽500-700/год

### SSL:
- **Let's Encrypt:** Бесплатно!

### API:
- **OpenAI:** ~$0.03-0.06 за запрос
- **NanoBanana:** ~$0.02-0.05 за изображение

**Итого:** ₽200-400/мес + домен + API costs

---

## ⚠️ Ограничения Beget

### Ресурсы:
- **RAM:** ограничен тарифом
- **CPU:** shared hosting (делится с другими)
- **Процессы:** могут убивать долгие процессы

### Решения:
1. **Оптимизируйте код** - быстрые ответы
2. **Кешируйте результаты**
3. **Используйте CDN** для статики
4. **Обновите тариф** если нужно больше ресурсов

---

## 🆘 Решение проблем

### Backend не запускается

```bash
# Проверьте логи
tail -f ~/logs/error.log

# Проверьте права
chmod +x ~/odezda/backend/passenger_wsgi.py

# Проверьте Python версию
python3 --version

# Проверьте зависимости
cd ~/odezda/backend
source venv/bin/activate
pip list
```

### CORS ошибки

Проверьте `backend/.env`:
```bash
cat ~/odezda/backend/.env | grep ALLOWED_ORIGINS
```

Должно быть:
```
ALLOWED_ORIGINS=https://ваш-домен.ru,http://ваш-домен.ru
```

### SSL не работает

1. Подождите 10-15 минут после получения
2. Очистите кеш браузера
3. Проверьте в панели Beget статус сертификата
4. Обратитесь в поддержку Beget

---

## 📚 Полезные ссылки

- Beget: https://beget.com
- Документация Beget: https://beget.com/ru/kb
- Поддержка: https://beget.com/ru/support
- Python на Beget: https://beget.com/ru/kb/how-to/python

---

## 🎯 Чек-лист

- [ ] Зарегистрировались на Beget
- [ ] Настроили домен
- [ ] Загрузили проект через SSH/FTP
- [ ] Настроили backend (Python + Passenger)
- [ ] Собрали и загрузили frontend build
- [ ] Настроили поддомен для API
- [ ] Получили SSL сертификат
- [ ] Обновили CORS в .env
- [ ] Проверили что сайт работает
- [ ] Настроили автозапуск через cron
- [ ] Добавили rate limiting

---

## 💡 Советы

1. **Используйте SSH** - быстрее чем FTP
2. **Настройте Git** - легче обновлять код
3. **Мониторьте логи** - быстро находите ошибки
4. **Делайте бэкапы** - Beget делает автоматически, но проверьте
5. **Общайтесь с поддержкой** - техподдержка Beget отзывчивая

---

## 🎉 Готово!

Ваш сайт теперь работает на Beget 24/7!

**Адрес:** `https://ваш-домен.ru`

**Удачи!** 🚀✨

