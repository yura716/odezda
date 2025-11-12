# 🐳 Docker руководство для Odezda AI

Это руководство описывает, как запустить Odezda AI используя Docker.

## 📋 Требования

- Docker 20.10+
- Docker Compose 2.0+
- OpenAI API ключ

## 🚀 Быстрый запуск

### 1. Клонируйте репозиторий

```bash
git clone https://github.com/your-username/odezda.git
cd odezda
```

### 2. Создайте .env файл

```bash
cp .env.example .env
```

Отредактируйте `.env` и добавьте ваш OpenAI API ключ:

```bash
OPENAI_API_KEY=sk-your-actual-api-key-here
```

### 3. Запустите с помощью Docker Compose

```bash
docker-compose up -d
```

Это запустит:
- Backend на `http://localhost:8000`
- Frontend на `http://localhost:80`

### 4. Откройте приложение

Перейдите в браузере на: `http://localhost`

## 📦 Команды Docker

### Запуск приложения

```bash
# Запустить в фоне
docker-compose up -d

# Запустить с логами
docker-compose up

# Пересобрать и запустить
docker-compose up --build
```

### Остановка приложения

```bash
# Остановить контейнеры
docker-compose stop

# Остановить и удалить контейнеры
docker-compose down

# Остановить и удалить все (включая volumes)
docker-compose down -v
```

### Просмотр логов

```bash
# Все логи
docker-compose logs

# Логи backend
docker-compose logs backend

# Логи frontend
docker-compose logs frontend

# Следить за логами в реальном времени
docker-compose logs -f
```

### Перезапуск сервисов

```bash
# Перезапустить все
docker-compose restart

# Перезапустить только backend
docker-compose restart backend
```

## 🔧 Разработка с Docker

### Горячая перезагрузка (Development mode)

Для разработки создайте `docker-compose.dev.yml`:

```yaml
version: '3.8'

services:
  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    volumes:
      - ./backend:/app
    command: uvicorn main:app --host 0.0.0.0 --port 8000 --reload
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
      target: build
    volumes:
      - ./frontend/src:/app/src
    command: npm start
    ports:
      - "3000:3000"
    environment:
      - REACT_APP_API_URL=http://localhost:8000
```

Запустите dev режим:

```bash
docker-compose -f docker-compose.dev.yml up
```

## 🛠️ Билд отдельных образов

### Backend

```bash
docker build -f Dockerfile.backend -t odezda-backend .
docker run -p 8000:8000 -e OPENAI_API_KEY=your-key odezda-backend
```

### Frontend

```bash
docker build -f Dockerfile.frontend -t odezda-frontend .
docker run -p 80:80 odezda-frontend
```

## 🌐 Деплой в продакшн

### Railway

1. Установите Railway CLI:
```bash
npm install -g @railway/cli
```

2. Логин:
```bash
railway login
```

3. Создайте проект:
```bash
railway init
```

4. Добавьте переменные окружения:
```bash
railway variables set OPENAI_API_KEY=your-key
```

5. Деплой:
```bash
railway up
```

### Render

1. Создайте `render.yaml`:
```yaml
services:
  - type: web
    name: odezda-backend
    env: docker
    dockerfilePath: ./Dockerfile.backend
    envVars:
      - key: OPENAI_API_KEY
        sync: false

  - type: web
    name: odezda-frontend
    env: docker
    dockerfilePath: ./Dockerfile.frontend
```

2. Подключите репозиторий к Render
3. Добавьте переменные окружения
4. Деплой произойдет автоматически

### DigitalOcean App Platform

1. Создайте `.do/app.yaml`:
```yaml
name: odezda-ai
services:
- name: backend
  dockerfile_path: Dockerfile.backend
  envs:
  - key: OPENAI_API_KEY
    scope: RUN_TIME
    type: SECRET
  http_port: 8000

- name: frontend
  dockerfile_path: Dockerfile.frontend
  http_port: 80
```

2. Подключите к GitHub
3. Деплой через веб-интерфейс

## 📊 Мониторинг

### Проверка здоровья контейнеров

```bash
docker-compose ps
```

### Использование ресурсов

```bash
docker stats
```

### Инспекция контейнера

```bash
docker inspect odezda-backend
docker inspect odezda-frontend
```

## 🐛 Отладка

### Войти в контейнер

```bash
# Backend
docker-compose exec backend /bin/bash

# Frontend
docker-compose exec frontend /bin/sh
```

### Проверить переменные окружения

```bash
docker-compose exec backend env
```

### Проверить файлы

```bash
docker-compose exec backend ls -la /app
```

## 🔒 Безопасность

### Лучшие практики:

1. **Не коммитьте .env файл**
   - Добавьте в `.gitignore`
   - Используйте `.env.example` для шаблона

2. **Используйте secrets для продакшена**
   ```yaml
   services:
     backend:
       secrets:
         - openai_api_key
   
   secrets:
     openai_api_key:
       external: true
   ```

3. **Ограничьте доступ к портам**
   ```yaml
   ports:
     - "127.0.0.1:8000:8000"  # Только localhost
   ```

4. **Используйте read-only файловую систему**
   ```yaml
   read_only: true
   tmpfs:
     - /tmp
   ```

## 📝 Переменные окружения

### Backend

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `OPENAI_API_KEY` | OpenAI API ключ | - (обязательно) |
| `HOST` | Хост сервера | `0.0.0.0` |
| `PORT` | Порт сервера | `8000` |
| `ALLOWED_ORIGINS` | CORS origins | `http://localhost:3000` |

### Frontend

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `REACT_APP_API_URL` | URL backend API | `http://localhost:8000` |

## 🎯 Оптимизация

### Уменьшение размера образов

1. **Multi-stage builds** (уже используется для frontend)
2. **Удаление ненужных файлов**:
   ```dockerfile
   RUN apt-get clean && rm -rf /var/lib/apt/lists/*
   ```
3. **Использование alpine образов**

### Кеширование слоев

Копируйте только необходимые файлы в правильном порядке:

```dockerfile
# Сначала зависимости (меняются редко)
COPY requirements.txt .
RUN pip install -r requirements.txt

# Потом код (меняется часто)
COPY . .
```

## 💾 Volumes

### Персистентное хранилище

Для сохранения данных между перезапусками:

```yaml
volumes:
  - ./data:/app/data
  - uploads:/app/uploads
```

### Backup volumes

```bash
# Создать backup
docker run --rm \
  -v odezda_uploads:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/uploads-backup.tar.gz /data

# Восстановить backup
docker run --rm \
  -v odezda_uploads:/data \
  -v $(pwd):/backup \
  alpine tar xzf /backup/uploads-backup.tar.gz -C /
```

## 🔧 Troubleshooting

### Проблема: Контейнер не запускается

```bash
# Проверьте логи
docker-compose logs backend

# Проверьте конфигурацию
docker-compose config
```

### Проблема: Не могу подключиться к backend

1. Проверьте, что backend запущен:
   ```bash
   curl http://localhost:8000/api/health
   ```

2. Проверьте CORS настройки в backend

3. Проверьте `REACT_APP_API_URL` в frontend

### Проблема: Out of memory

Увеличьте лимиты памяти:

```yaml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 1G
```

---

## 📚 Дополнительные ресурсы

- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)

---

**Готово! Теперь ваше приложение работает в Docker! 🐳**


