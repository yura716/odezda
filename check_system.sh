#!/bin/bash

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   🔍 Проверка системы Odezda AI      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

ERRORS=0

# Проверка Python
echo -n "Проверяю Python... "
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    PYTHON_MAJOR=$(echo $PYTHON_VERSION | cut -d'.' -f1)
    PYTHON_MINOR=$(echo $PYTHON_VERSION | cut -d'.' -f2)
    
    if [ "$PYTHON_MAJOR" -ge 3 ] && [ "$PYTHON_MINOR" -ge 8 ]; then
        echo -e "${GREEN}✅ Python $PYTHON_VERSION${NC}"
    else
        echo -e "${RED}❌ Python $PYTHON_VERSION (требуется 3.8+)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌ Python не найден${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Проверка Node.js
echo -n "Проверяю Node.js... "
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version | cut -d'v' -f2)
    NODE_MAJOR=$(echo $NODE_VERSION | cut -d'.' -f1)
    
    if [ "$NODE_MAJOR" -ge 16 ]; then
        echo -e "${GREEN}✅ Node.js v$NODE_VERSION${NC}"
    else
        echo -e "${RED}❌ Node.js v$NODE_VERSION (требуется 16+)${NC}"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌ Node.js не найден${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Проверка npm
echo -n "Проверяю npm... "
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo -e "${GREEN}✅ npm v$NPM_VERSION${NC}"
else
    echo -e "${RED}❌ npm не найден${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Проверка структуры проекта
echo -n "Проверяю структуру проекта... "
if [ -d "backend" ] && [ -d "frontend" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Отсутствуют директории backend или frontend${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Проверка backend файлов
echo -n "Проверяю файлы backend... "
if [ -f "backend/main.py" ] && [ -f "backend/requirements.txt" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Отсутствуют необходимые файлы backend${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Проверка frontend файлов
echo -n "Проверяю файлы frontend... "
if [ -f "frontend/package.json" ] && [ -f "frontend/src/App.js" ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ Отсутствуют необходимые файлы frontend${NC}"
    ERRORS=$((ERRORS + 1))
fi

# Проверка .env файла backend
echo -n "Проверяю конфигурацию backend... "
if [ -f "backend/.env" ]; then
    if grep -q "OPENAI_API_KEY=sk-" "backend/.env"; then
        echo -e "${GREEN}✅ OpenAI API ключ настроен${NC}"
    else
        echo -e "${YELLOW}⚠️  OpenAI API ключ не настроен${NC}"
        echo -e "${YELLOW}   Отредактируйте backend/.env и добавьте ваш ключ${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Файл .env не найден${NC}"
    if [ -f "backend/env_example.txt" ]; then
        echo -e "${YELLOW}   Создаю из шаблона...${NC}"
        cp backend/env_example.txt backend/.env
        echo -e "${YELLOW}   Отредактируйте backend/.env и добавьте OpenAI API ключ${NC}"
    fi
fi

# Проверка портов
echo -n "Проверяю порт 8000 (backend)... "
if lsof -Pi :8000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Порт занят${NC}"
    echo -e "${YELLOW}   Остановите процесс или измените порт в backend/.env${NC}"
else
    echo -e "${GREEN}✅ Свободен${NC}"
fi

echo -n "Проверяю порт 3000 (frontend)... "
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    echo -e "${YELLOW}⚠️  Порт занят${NC}"
    echo -e "${YELLOW}   Остановите процесс или React использует другой порт${NC}"
else
    echo -e "${GREEN}✅ Свободен${NC}"
fi

# Проверка зависимостей Python
echo -n "Проверяю зависимости Python... "
if [ -d "backend/venv" ]; then
    echo -e "${GREEN}✅ Виртуальное окружение существует${NC}"
else
    echo -e "${YELLOW}⚠️  Виртуальное окружение не найдено${NC}"
    echo -e "${YELLOW}   Будет создано при первом запуске${NC}"
fi

# Проверка зависимостей Node.js
echo -n "Проверяю зависимости Node.js... "
if [ -d "frontend/node_modules" ]; then
    echo -e "${GREEN}✅ Установлены${NC}"
else
    echo -e "${YELLOW}⚠️  Не установлены${NC}"
    echo -e "${YELLOW}   Будут установлены при первом запуске${NC}"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Все проверки пройдены!${NC}"
    echo ""
    echo -e "Для запуска приложения выполните:"
    echo -e "${GREEN}./start.sh${NC}"
    echo ""
    echo -e "Или по отдельности:"
    echo -e "${GREEN}./start_backend.sh${NC}  # Backend на порту 8000"
    echo -e "${GREEN}./start_frontend.sh${NC} # Frontend на порту 3000"
else
    echo -e "${RED}❌ Найдено ошибок: $ERRORS${NC}"
    echo ""
    echo -e "Пожалуйста, исправьте ошибки перед запуском."
    echo -e "См. подробную инструкцию: ${BLUE}SETUP.md${NC}"
fi

echo -e "${BLUE}════════════════════════════════════════${NC}"


