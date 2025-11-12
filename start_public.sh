#!/bin/bash

# 🌐 Скрипт для публичного доступа к локальному серверу через ngrok
# Использование: ./start_public.sh

set -e

echo "=========================================="
echo "🌐 Запуск сайта с публичным доступом"
echo "=========================================="
echo ""

# Проверка ngrok
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok не установлен!"
    echo ""
    echo "Установите ngrok:"
    echo "  brew install ngrok"
    echo ""
    echo "Или скачайте с https://ngrok.com/download"
    exit 1
fi

# Проверка авторизации ngrok
if ! ngrok config check &> /dev/null; then
    echo "⚠️ ngrok не авторизован!"
    echo ""
    echo "1. Зарегистрируйтесь на https://ngrok.com (бесплатно)"
    echo "2. Скопируйте токен с dashboard"
    echo "3. Выполните: ngrok config add-authtoken ваш_токен"
    echo ""
    exit 1
fi

# Получаем директорию скрипта
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Функция очистки при выходе
cleanup() {
    echo ""
    echo "🛑 Останавливаем серверы..."
    
    # Убиваем все дочерние процессы
    jobs -p | xargs -r kill 2>/dev/null || true
    
    # Убиваем ngrok
    pkill -f ngrok 2>/dev/null || true
    
    echo "✅ Все остановлено"
    exit 0
}

trap cleanup EXIT INT TERM

# Проверка backend зависимостей
echo "📦 Проверка backend..."
if [ ! -d "$SCRIPT_DIR/backend/venv" ]; then
    echo "❌ Virtual environment не найден!"
    echo "Выполните сначала: cd backend && python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 1
fi

# Проверка frontend зависимостей
echo "📦 Проверка frontend..."
if [ ! -d "$SCRIPT_DIR/frontend/node_modules" ]; then
    echo "❌ node_modules не найден!"
    echo "Выполните сначала: cd frontend && npm install"
    exit 1
fi

# Проверка .env файла
if [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
    echo "❌ Файл backend/.env не найден!"
    echo "Создайте файл .env с API ключами"
    exit 1
fi

echo ""
echo "=========================================="
echo "🚀 Запускаю серверы..."
echo "=========================================="
echo ""

# Запуск backend
echo "🖥️  Запуск backend на http://localhost:8000..."
cd "$SCRIPT_DIR/backend"
source venv/bin/activate
python main.py > /tmp/odezda_backend.log 2>&1 &
BACKEND_PID=$!

# Ждем запуска backend
sleep 3

# Проверка что backend запустился
if ! ps -p $BACKEND_PID > /dev/null; then
    echo "❌ Backend не запустился!"
    echo "Проверьте логи: tail -f /tmp/odezda_backend.log"
    exit 1
fi

echo "✅ Backend запущен (PID: $BACKEND_PID)"
echo ""

# Запуск frontend
echo "🎨 Запуск frontend на http://localhost:3000..."
cd "$SCRIPT_DIR/frontend"
BROWSER=none npm start > /tmp/odezda_frontend.log 2>&1 &
FRONTEND_PID=$!

# Ждем запуска frontend
echo "⏳ Ожидание запуска frontend (это может занять ~30 секунд)..."
sleep 30

# Проверка что frontend запустился
if ! ps -p $FRONTEND_PID > /dev/null; then
    echo "❌ Frontend не запустился!"
    echo "Проверьте логи: tail -f /tmp/odezda_frontend.log"
    exit 1
fi

echo "✅ Frontend запущен (PID: $FRONTEND_PID)"
echo ""

# Запуск ngrok
echo "🌐 Создаю публичный туннель через ngrok..."
ngrok http 3000 > /dev/null &
NGROK_PID=$!

# Ждем запуска ngrok
sleep 3

# Получаем публичный URL
echo "⏳ Получаю публичный URL..."
sleep 2

NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[a-zA-Z0-9.-]*\.ngrok[a-zA-Z0-9.-]*')

if [ -z "$NGROK_URL" ]; then
    echo "❌ Не удалось получить ngrok URL!"
    echo "Проверьте что ngrok авторизован: ngrok config check"
    exit 1
fi

echo ""
echo "=========================================="
echo "✅ ВСЁ ГОТОВО!"
echo "=========================================="
echo ""
echo "🌐 Публичный URL (поделитесь с другими):"
echo ""
echo "   $NGROK_URL"
echo ""
echo "=========================================="
echo ""
echo "📊 Локальные URL (только для вас):"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:8000"
echo "   ngrok UI: http://localhost:4040"
echo ""
echo "📝 Логи:"
echo "   Backend:  tail -f /tmp/odezda_backend.log"
echo "   Frontend: tail -f /tmp/odezda_frontend.log"
echo ""
echo "⚠️  ВАЖНО:"
echo "   1. Не закрывайте это окно терминала!"
echo "   2. Компьютер должен быть включен и подключен к интернету"
echo "   3. Бесплатная версия ngrok: URL меняется при перезапуске"
echo "   4. Не забудьте добавить ngrok URL в ALLOWED_ORIGINS!"
echo ""
echo "🛑 Для остановки нажмите Ctrl+C"
echo ""
echo "=========================================="

# Проверяем CORS настройки
echo "🔍 Проверка CORS настроек..."
if grep -q "$NGROK_URL" "$SCRIPT_DIR/backend/.env" 2>/dev/null; then
    echo "✅ CORS настроен правильно"
else
    echo ""
    echo "⚠️  ВНИМАНИЕ: Нужно обновить CORS!"
    echo ""
    echo "Добавьте в backend/.env:"
    echo "ALLOWED_ORIGINS=http://localhost:3000,$NGROK_URL"
    echo ""
    echo "Затем перезапустите скрипт"
fi

echo ""
echo "Ожидание... (нажмите Ctrl+C для остановки)"
echo ""

# Бесконечный цикл
while true; do
    # Проверяем что процессы еще живы
    if ! ps -p $BACKEND_PID > /dev/null; then
        echo "❌ Backend остановился!"
        exit 1
    fi
    
    if ! ps -p $FRONTEND_PID > /dev/null; then
        echo "❌ Frontend остановился!"
        exit 1
    fi
    
    if ! ps -p $NGROK_PID > /dev/null; then
        echo "❌ ngrok остановился!"
        exit 1
    fi
    
    sleep 5
done

