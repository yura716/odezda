# 🚀 Деплой сайта в продакшн

## 📌 Обзор

Есть 3 основных варианта развертывания:

1. **Бесплатный** - Railway.app + Vercel (хорошо для старта)
2. **Недорогой** - VPS сервер ($5-10/мес)
3. **Премиум** - AWS/Google Cloud (масштабируемо, дорого)

---

# 🆓 Вариант 1: Бесплатный деплой (Railway + Vercel)

## 📦 Что вам понадобится:

1. Аккаунт GitHub (для хранения кода)
2. Аккаунт Railway.app (для backend)
3. Аккаунт Vercel (для frontend)
4. OpenAI API ключ
5. NanoBanana API ключ

---

## 🔧 Шаг 1: Подготовка проекта

### 1.1 Создайте GitHub репозиторий

```bash
cd /Users/urij/Documents/odezda

# Инициализируйте git (если еще не сделано)
git init
git add .
git commit -m "Initial commit"

# Создайте репозиторий на GitHub.com
# Затем подключите его:
git remote add origin https://github.com/ваш-username/odezda.git
git branch -M main
git push -u origin main
```

### 1.2 Убедитесь что `.env` в `.gitignore`

**Важно!** Не коммитьте `.env` файл с секретными ключами!

Проверьте что в `.gitignore` есть:
```
.env
backend/.env
```

---

## 🖥️ Шаг 2: Деплой Backend на Railway.app

### 2.1 Регистрация

1. Зайдите на https://railway.app
2. Войдите через GitHub
3. Нажмите "New Project"

### 2.2 Создайте проект

1. Выберите "Deploy from GitHub repo"
2. Выберите ваш репозиторий `odezda`
3. Railway автоматически определит Python приложение

### 2.3 Настройте переменные окружения

В настройках проекта добавьте:

```
OPENAI_API_KEY=ваш_ключ_openai
NANOBANANA_API_KEY=ваш_ключ_nanobanana
HOST=0.0.0.0
PORT=8000
ALLOWED_ORIGINS=https://ваш-фронтенд.vercel.app
```

### 2.4 Настройте деплой

Создайте файл `railway.json` в корне проекта:

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS",
    "buildCommand": "cd backend && pip install -r requirements.txt"
  },
  "deploy": {
    "startCommand": "cd backend && uvicorn main:app --host 0.0.0.0 --port $PORT",
    "healthcheckPath": "/",
    "healthcheckTimeout": 100
  }
}
```

### 2.5 Получите URL backend

После деплоя Railway выдаст URL типа:
```
https://odezda-backend-production.up.railway.app
```

**Сохраните этот URL!** Он понадобится для frontend.

---

## 🎨 Шаг 3: Деплой Frontend на Vercel

### 3.1 Регистрация

1. Зайдите на https://vercel.com
2. Войдите через GitHub
3. Нажмите "Add New Project"

### 3.2 Импортируйте проект

1. Выберите репозиторий `odezda`
2. Настройте проект:
   - **Framework Preset:** Create React App
   - **Root Directory:** `frontend`
   - **Build Command:** `npm run build`
   - **Output Directory:** `build`

### 3.3 Настройте переменные окружения

Добавьте:
```
REACT_APP_API_URL=https://odezda-backend-production.up.railway.app
```

### 3.4 Обновите код frontend

Откройте `frontend/src/components/UploadForm.js` и измените:

```javascript
// Было:
const response = await fetch('http://localhost:8000/api/analyze', {

// Стало:
const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';
const response = await fetch(`${API_URL}/api/analyze`, {
```

### 3.5 Деплой!

Vercel автоматически задеплоит ваш сайт и выдаст URL:
```
https://odezda.vercel.app
```

### 3.6 Обновите ALLOWED_ORIGINS в Railway

Вернитесь в Railway и обновите переменную:
```
ALLOWED_ORIGINS=https://odezda.vercel.app
```

---

## ✅ Готово!

Ваш сайт доступен по адресу:
```
https://odezda.vercel.app
```

Любой человек может:
1. Открыть сайт
2. Загрузить фото
3. Получить рекомендации одежды
4. Увидеть сгенерированное изображение

---

# 💰 Вариант 2: VPS сервер (рекомендую после тестирования)

## Провайдеры:

- **Hetzner** - €4.5/мес (лучшая цена/качество)
- **DigitalOcean** - $6/мес (простота)
- **Linode** - $5/мес (надежность)

## Быстрый деплой с Docker:

### 1. Арендуйте VPS

Выберите:
- OS: Ubuntu 22.04
- RAM: минимум 2GB
- Storage: 20GB+

### 2. Подключитесь по SSH

```bash
ssh root@ваш-ip-адрес
```

### 3. Установите Docker

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Установите Docker Compose
apt install docker-compose -y
```

### 4. Клонируйте проект

```bash
git clone https://github.com/ваш-username/odezda.git
cd odezda
```

### 5. Настройте переменные

```bash
# Backend .env
cat > backend/.env << EOF
OPENAI_API_KEY=ваш_ключ_openai
NANOBANANA_API_KEY=ваш_ключ_nanobanana
HOST=0.0.0.0
PORT=8000
ALLOWED_ORIGINS=http://ваш-ip-адрес
EOF

# Frontend .env
cat > frontend/.env << EOF
REACT_APP_API_URL=http://ваш-ip-адрес:8000
EOF
```

### 6. Запустите с Docker Compose

```bash
docker-compose up -d
```

### 7. Настройте Nginx (опционально)

Для красивого домена и HTTPS:

```bash
# Установите Nginx
apt install nginx -y

# Создайте конфиг
cat > /etc/nginx/sites-available/odezda << 'EOF'
server {
    listen 80;
    server_name ваш-домен.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://localhost:8000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
EOF

# Активируйте конфиг
ln -s /etc/nginx/sites-available/odezda /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### 8. Настройте HTTPS (бесплатно с Let's Encrypt)

```bash
apt install certbot python3-certbot-nginx -y
certbot --nginx -d ваш-домен.com
```

---

## 🔒 Безопасность

### Обязательно:

1. **Используйте HTTPS** (Let's Encrypt - бесплатно)
2. **Ограничьте CORS** (только ваш домен)
3. **Настройте firewall:**
   ```bash
   ufw allow 22    # SSH
   ufw allow 80    # HTTP
   ufw allow 443   # HTTPS
   ufw enable
   ```
4. **Регулярно обновляйте:**
   ```bash
   apt update && apt upgrade -y
   ```

---

## 📊 Мониторинг

### Логи Railway:
- Смотрите в дашборде Railway

### Логи VPS:
```bash
# Backend логи
docker-compose logs -f backend

# Frontend логи
docker-compose logs -f frontend
```

---

## 💸 Стоимость

### Бесплатный вариант (Railway + Vercel):
- **Railway:** 500 часов/мес бесплатно (~20 дней)
- **Vercel:** 100GB bandwidth/мес
- **OpenAI:** ~$0.03-0.06 за запрос
- **NanoBanana:** ~$0.02-0.05 за изображение

**Итого:** Зависит от трафика. ~$5-20/мес при 100-500 запросов/мес

### VPS вариант:
- **VPS:** €4.5-10/мес
- **Домен:** ~$10-15/год
- **OpenAI + NanoBanana:** по использованию

**Итого:** ~$10-15/мес + API costs

---

## 🚨 Важные замечания

### 1. API ключи - это деньги!

⚠️ Если кто-то использует ваш сайт, они тратят **ваши** деньги на API!

**Решения:**
- Добавить аутентификацию (только зарегистрированные пользователи)
- Лимит запросов (rate limiting)
- Ввести платный доступ

### 2. Создайте файл с лимитами

Добавьте в `backend/main.py`:

```python
from fastapi import Request
from collections import defaultdict
import time

# Простой rate limiter
request_counts = defaultdict(list)

def check_rate_limit(ip: str, limit: int = 5, window: int = 3600):
    """Ограничение: limit запросов в window секунд"""
    now = time.time()
    # Очищаем старые запросы
    request_counts[ip] = [t for t in request_counts[ip] if now - t < window]
    
    if len(request_counts[ip]) >= limit:
        return False
    
    request_counts[ip].append(now)
    return True

@app.post("/api/analyze")
async def analyze_photo(request: Request, ...):
    # Проверяем лимит
    client_ip = request.client.host
    if not check_rate_limit(client_ip, limit=10, window=3600):
        raise HTTPException(status_code=429, detail="Слишком много запросов. Попробуйте позже.")
    
    # ... остальной код
```

---

## 🎯 Рекомендованный план действий

### Этап 1: Тестирование (бесплатно)
1. ✅ Деплой на Railway + Vercel
2. ✅ Поделитесь ссылкой с друзьями
3. ✅ Соберите фидбек
4. ✅ Мониторьте затраты на API

### Этап 2: Запуск (если есть пользователи)
1. ✅ Переезд на VPS
2. ✅ Купите домен
3. ✅ Настройте HTTPS
4. ✅ Добавьте rate limiting
5. ✅ Настройте мониторинг

### Этап 3: Монетизация (если популярно)
1. ✅ Добавьте регистрацию
2. ✅ Введите платные планы
3. ✅ Интегрируйте оплату (Stripe, PayPal)
4. ✅ Масштабируйте инфраструктуру

---

## 📚 Полезные ссылки

- Railway.app: https://railway.app
- Vercel: https://vercel.com
- Hetzner: https://www.hetzner.com/cloud
- DigitalOcean: https://www.digitalocean.com
- Let's Encrypt: https://letsencrypt.org
- Docker документация: https://docs.docker.com

---

## 🆘 Помощь

Если нужна помощь с деплоем:
1. Проверьте логи (Railway dashboard или `docker-compose logs`)
2. Убедитесь что все переменные окружения настроены
3. Проверьте что CORS разрешает запросы с вашего фронтенда
4. Проверьте что API ключи корректные

---

**Удачи с запуском!** 🚀✨

