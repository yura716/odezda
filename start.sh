#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   🚀 Запуск Odezda AI                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# Проверка наличия Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}❌ Python 3 не найден. Пожалуйста, установите Python 3.8+${NC}"
    exit 1
fi

# Проверка наличия Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js не найден. Пожалуйста, установите Node.js 16+${NC}"
    exit 1
fi

# Проверка .env файла для backend
if [ ! -f "backend/.env" ]; then
    echo -e "${YELLOW}⚠️  Файл backend/.env не найден${NC}"
    echo "Создаю из шаблона..."
    cp backend/env_example.txt backend/.env
    echo -e "${YELLOW}⚠️  ВАЖНО: Откройте backend/.env и добавьте ваш OpenAI API ключ!${NC}"
    echo ""
    read -p "Нажмите Enter после настройки .env файла..."
fi

# Запуск Backend
echo -e "${GREEN}📦 Запускаю Backend сервер...${NC}"
cd backend

# Создание виртуального окружения если нужно
if [ ! -d "venv" ]; then
    echo "Создаю виртуальное окружение..."
    python3 -m venv venv
fi

# Активация виртуального окружения
source venv/bin/activate

# Установка зависимостей
echo "Устанавливаю зависимости..."
pip install -q -r requirements.txt

# Запуск backend в фоне
echo "Запускаю backend на http://localhost:8000"
python main.py &
BACKEND_PID=$!

cd ..

# Задержка для запуска backend
sleep 3

# Запуск Frontend
echo -e "${GREEN}🎨 Запускаю Frontend...${NC}"
cd frontend

# Установка зависимостей если нужно
if [ ! -d "node_modules" ]; then
    echo "Устанавливаю npm зависимости..."
    npm install
fi

# Создание .env если нужно
if [ ! -f ".env" ]; then
    cp .env.example .env
fi

# Запуск frontend
echo "Запускаю frontend на http://localhost:3000"
npm start &
FRONTEND_PID=$!

cd ..

echo ""
echo -e "${GREEN}✅ Приложение запущено!${NC}"
echo ""
echo -e "Backend:  ${GREEN}http://localhost:8000${NC}"
echo -e "Frontend: ${GREEN}http://localhost:3000${NC}"
echo ""
echo -e "${YELLOW}Для остановки нажмите Ctrl+C${NC}"
echo ""

# Ожидание завершения
wait $BACKEND_PID $FRONTEND_PID


