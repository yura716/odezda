# 🧠 Логика работы проекта Odezda AI

## 📋 Содержание
1. [Общая архитектура](#общая-архитектура)
2. [Технологический стек](#технологический-стек)
3. [Поток данных (Data Flow)](#поток-данных)
4. [Frontend логика](#frontend-логика)
5. [Backend логика](#backend-логика)
6. [Интеграция с внешними API](#интеграция-с-внешними-api)
7. [Обработка изображений](#обработка-изображений)
8. [Обработка ошибок](#обработка-ошибок)

---

## 🏗️ Общая архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                         ПОЛЬЗОВАТЕЛЬ                             │
│                    (Web браузер / Мобильный)                     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTPS
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FRONTEND (React App)                          │
│  ┌─────────────┐  ┌──────────────┐  ┌───────────────┐          │
│  │ UploadForm  │  │   Results    │  │   App.js      │          │
│  │  Component  │  │   Component  │  │   (Router)    │          │
│  └─────────────┘  └──────────────┘  └───────────────┘          │
│          │                                    │                  │
│          │ Axios POST /api/analyze           │                  │
│          └────────────────────────────────────┘                  │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             │ HTTP Request
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                    BACKEND (FastAPI)                             │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  main.py - Основной API сервер                           │  │
│  │                                                           │  │
│  │  Endpoints:                                               │  │
│  │  • GET  /           → Проверка работоспособности         │  │
│  │  • POST /api/analyze → Главная логика обработки          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                             │                                   │
│          ┌──────────────────┼──────────────────┐               │
│          ▼                  ▼                  ▼               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ OpenAI API   │  │ NanoBanana   │  │  Imgur API   │        │
│  │ (GPT-4o)     │  │  API         │  │              │        │
│  │              │  │              │  │              │        │
│  │ • Анализ     │  │ • Генерация  │  │ • Хостинг    │        │
│  │   фото       │  │   фото       │  │   изображений│        │
│  │ • Рекомен-   │  │ • Virtual    │  │              │        │
│  │   дации      │  │   try-on     │  │              │        │
│  └──────────────┘  └──────────────┘  └──────────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Технологический стек

### Frontend
- **React 18.2.0** - UI библиотека
- **Axios 1.6.0** - HTTP клиент для API запросов
- **CSS3** - Стилизация с градиентами и анимациями
- **Create React App** - Сборка и деплой

### Backend
- **FastAPI 0.104.1** - Современный веб-фреймворк
- **Python 3.9+** - Основной язык
- **Uvicorn** - ASGI сервер
- **Pillow (PIL)** - Обработка изображений
- **OpenAI API 2.7.2** - GPT-4o Vision для анализа
- **Requests** - HTTP клиент для внешних API

### Внешние сервисы
- **OpenAI GPT-4o** - Анализ фотографий и рекомендации
- **NanoBanana API** - AI генерация изображений (virtual try-on)
- **Imgur** - Временный хостинг изображений

### Деплой
- **Railway.app** - Хостинг frontend и backend
- **GitHub** - Версионирование и CI/CD
- **Nginx** (опционально) - Reverse proxy для локального доступа

---

## 🔄 Поток данных (Data Flow)

### Полный цикл обработки запроса:

```
1. ПОЛЬЗОВАТЕЛЬ загружает фото + выбирает стиль
                    │
                    ▼
2. FRONTEND отправляет POST /api/analyze
   • FormData с image (файл)
   • style (строка: "Casual", "Business", etc.)
                    │
                    ▼
3. BACKEND получает запрос
                    │
                    ├─→ 3.1. Сохраняет фото локально
                    │
                    ├─→ 3.2. Исправляет ориентацию (EXIF)
                    │
                    ├─→ 3.3. Загружает на Imgur (публичный URL)
                    │
                    ├─→ 3.4. Отправляет в OpenAI GPT-4o Vision
                    │        • Анализ внешности
                    │        • 5 рекомендаций одежды
                    │        • Советы по стилю
                    │
                    ├─→ 3.5. Отправляет в NanoBanana API
                    │        • Оригинальное фото (Imgur URL)
                    │        • Промпт с описанием одежды
                    │        • Polling результата (до 3 минут)
                    │
                    ├─→ 3.6. Скачивает сгенерированное фото
                    │
                    ├─→ 3.7. Поворачивает на 90° вправо
                    │
                    ├─→ 3.8. Загружает повернутое на Imgur
                    │
                    └─→ 3.9. Формирует JSON ответ
                    │
                    ▼
4. FRONTEND получает JSON:
   {
     "analysis": "...",
     "recommendations": [...],
     "style_tips": [...],
     "generated_image": "https://..."
   }
                    │
                    ▼
5. FRONTEND отображает результаты:
   • Сгенерированное изображение (с fallback)
   • Анализ внешности
   • Советы по стилю
   • Карточки рекомендаций с ссылками на магазины
```

---

## 💻 Frontend логика

### Структура компонентов

```
src/
├── App.js                    # Главный компонент, управление состоянием
├── App.css                   # Глобальные стили
├── components/
│   ├── UploadForm.js         # Форма загрузки фото + выбор стиля
│   ├── UploadForm.css
│   ├── Results.js            # Отображение результатов
│   └── Results.css
├── index.js                  # Точка входа React
└── index.css                 # Базовые стили
```

### App.js - Главная логика

```javascript
// Состояния приложения
const [selectedFile, setSelectedFile] = useState(null);
const [selectedStyle, setSelectedStyle] = useState('');
const [loading, setLoading] = useState(false);
const [results, setResults] = useState(null);
const [error, setError] = useState(null);

// Обработчик отправки формы
const handleSubmit = async (file, style) => {
  setLoading(true);
  setError(null);
  
  // Формирование FormData
  const formData = new FormData();
  formData.append('image', file);
  formData.append('style', style);
  
  try {
    // API запрос
    const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';
    const response = await axios.post(`${API_URL}/api/analyze`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
      timeout: 200000  // 200 секунд (генерация может занять до 3 минут)
    });
    
    setResults(response.data);
  } catch (error) {
    // Обработка ошибок
    setError(error.response?.data?.detail || 'Ошибка соединения');
  } finally {
    setLoading(false);
  }
};
```

### UploadForm.js - Форма загрузки

**Функциональность:**
1. Предпросмотр загруженного фото
2. Выбор стиля из предопределенного списка
3. Валидация формата файла (JPEG, PNG, WebP)
4. Валидация размера файла (макс. 10MB)
5. Отображение прогресса загрузки

**Доступные стили:**
- Casual (Повседневный)
- Business (Деловой)
- Sport (Спортивный)
- Evening (Вечерний)
- Street (Уличный)
- Minimalist (Минималистичный)
- Vintage (Винтажный)
- Romantic (Романтичный)

### Results.js - Отображение результатов

**Компоненты результата:**

1. **Сгенерированное изображение**
   - Основное изображение с обработкой ошибок
   - Fallback если изображение не загружается
   - Ссылка "Открыть в полном размере"
   - При ошибке: кнопка "Открыть напрямую"

2. **Анализ внешности**
   - Описание внешности пользователя
   - Тип фигуры, цветотип, особенности

3. **Советы по стилю**
   - Список рекомендаций от GPT-4o
   - Индивидуальные для выбранного стиля

4. **Рекомендации одежды (5 карточек)**
   - Название вещи
   - Подробное описание
   - Обоснование выбора
   - Ссылки на магазины (Lamoda, Wildberries, Ozon)

---

## ⚙️ Backend логика

### main.py - Структура

```python
# Импорты и инициализация
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from openai import OpenAI
import requests
from PIL import Image

app = FastAPI()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# CORS настройки
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене: конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Основные функции

#### 1. `fix_image_orientation(image_data: bytes) -> bytes`
**Назначение:** Исправляет ориентацию фото на основе EXIF данных

**Логика:**
```python
# 1. Открываем изображение из bytes
image = Image.open(io.BytesIO(image_data))

# 2. Получаем EXIF данные
exif = image.getexif()
orientation = exif.get(0x0112, 1)  # Tag 274 = Orientation

# 3. Поворачиваем согласно EXIF
if orientation == 3:
    image = image.rotate(180, expand=True)
elif orientation == 6:
    image = image.rotate(270, expand=True)
elif orientation == 8:
    image = image.rotate(90, expand=True)

# 4. Удаляем EXIF и возвращаем bytes
```

**Зачем:** Многие телефоны сохраняют фото с EXIF ориентацией вместо реального поворота. Браузеры и API могут игнорировать EXIF, показывая неправильную ориентацию.

---

#### 2. `upload_image_to_imgur(image_data: bytes) -> str`
**Назначение:** Загружает изображение на Imgur и возвращает публичный HTTPS URL

**Логика:**
```python
# 1. Исправляем ориентацию
fixed_data = fix_image_orientation(image_data)

# 2. Конвертируем в base64
image_b64 = base64.b64encode(fixed_data).decode('utf-8')

# 3. Отправляем в Imgur API
url = "https://api.imgur.com/3/image"
headers = {"Authorization": "Client-ID 546c25a59c58ad7"}
response = requests.post(url, headers=headers, data={
    "image": image_b64,
    "type": "base64"
})

# 4. Получаем URL и конвертируем в HTTPS
image_url = response.json()["data"]["link"]
if image_url.startswith("http://"):
    image_url = image_url.replace("http://", "https://", 1)

return image_url
```

**Зачем:** 
- NanoBanana API требует публичный URL (не может обратиться к localhost)
- HTTPS обязателен для работы на мобильных браузерах
- Imgur бесплатный и не требует регистрации

---

#### 3. `analyze_image_and_style(image_url: str, style: str) -> dict`
**Назначение:** Анализирует фото через OpenAI GPT-4o Vision и генерирует рекомендации

**Логика:**
```python
# 1. Формируем промпт для GPT-4o
prompt = f"""
Проанализируй фотографию человека и подбери одежду в стиле {style}.

ВАЖНО: Отвечай СТРОГО в формате JSON.

{{
  "analysis": "описание внешности на русском",
  "recommendations": [
    {{
      "item": "название вещи на английском",
      "description": "подробное описание на русском",
      "why": "почему подходит на русском",
      "search_query": "запрос для поиска на русском"
    }}
  ],
  "style_tips": ["совет 1", "совет 2", ...]
}}
"""

# 2. Отправляем запрос в OpenAI
response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{
        "role": "user",
        "content": [
            {"type": "text", "text": prompt},
            {"type": "image_url", "image_url": {"url": image_url}}
        ]
    }],
    max_tokens=2000
)

# 3. Парсим JSON из ответа
content = response.choices[0].message.content
# Удаляем markdown форматирование ```json ... ```
json_str = content.replace("```json", "").replace("```", "").strip()
result = json.loads(json_str)

# 4. Добавляем ссылки на магазины для каждой рекомендации
for rec in result["recommendations"]:
    search_query = rec.get("search_query", rec["item"])
    encoded_query = quote(search_query)  # URL-кодирование русских букв
    
    rec["shop_links"] = [
        {
            "name": "Lamoda",
            "url": f"https://www.lamoda.ru/catalogsearch/result/?q={encoded_query}"
        },
        {
            "name": "Wildberries",
            "url": f"https://www.wildberries.ru/catalog/0/search.aspx?search={encoded_query}"
        },
        {
            "name": "Ozon",
            "url": f"https://www.ozon.ru/search/?text={encoded_query}"
        }
    ]

return result
```

**Параметры:**
- **model:** `gpt-4o` - мультимодальная модель с vision
- **max_tokens:** 2000 - достаточно для 5 рекомендаций
- **temperature:** по умолчанию (0.7) для креативности

**Обработка ошибок:**
- Проверка пустого ответа
- Проверка наличия `choices`
- Try/catch для JSON парсинга
- Graceful degradation при ошибке

---

#### 4. `generate_outfit_image_nanobanana(image_url: str, recommendations: list, style: str) -> str`
**Назначение:** Генерирует изображение человека в рекомендованной одежде через NanoBanana API

**Логика:**

```python
# 1. Формируем промпт из конкретных рекомендаций
clothing_items = []
for rec in recommendations[:5]:
    item_name = rec.get("item", "")
    description = rec.get("description", "")
    clothing_items.append(f"{item_name} ({description})")

clothing_list = ", ".join(clothing_items)

prompt = f"""Change the person's clothing to exactly these items: {clothing_list}.
Keep the person's face, body shape, skin tone, hair unchanged.
Only modify clothing. Style: {style}. Photorealistic."""

# 2. Отправляем задачу в NanoBanana
url = "https://api.nanobananaapi.ai/api/v1/nanobanana/generate"
headers = {
    "Authorization": f"Bearer {NANOBANANA_API_KEY}",
    "Content-Type": "application/json"
}
data = {
    "prompt": prompt,
    "type": "IMAGETOIAMGE",  # Режим редактирования
    "imageUrls": [image_url],
    "numImages": 1,
    "image_size": "4:3",
    "callBackUrl": "https://callback.example.com"
}

response = requests.post(url, headers=headers, json=data, timeout=30)
task_id = response.json()["data"]["taskId"]

# 3. Polling результата (до 180 секунд)
max_attempts = 90
for attempt in range(max_attempts):
    time.sleep(2)
    
    status_url = f"https://api.nanobananaapi.ai/api/v1/nanobanana/record-info?taskId={task_id}"
    status_response = requests.get(status_url, headers={"Authorization": f"Bearer {api_key}"})
    
    if status_response.status_code == 200:
        status_data = status_response.json()
        success_flag = status_data["data"]["successFlag"]
        
        # 0 = generating, 1 = success, 2/3 = failed
        if success_flag == 1:
            result_url = status_data["data"]["response"]["resultImageUrl"]
            
            # 4. Поворачиваем изображение и загружаем на Imgur
            fixed_url = fix_result_image_orientation(result_url)
            return fixed_url
        elif success_flag in [2, 3]:
            return None  # Ошибка генерации
        # else: continue polling

# Timeout после 180 секунд
return None
```

**Параметры NanoBanana:**
- **type:** `IMAGETOIAMGE` - редактирование существующего фото
- **image_size:** `4:3` - горизонтальная ориентация
- **numImages:** 1 - одно изображение

**Polling стратегия:**
- Интервал: 2 секунды
- Максимум попыток: 90 (= 180 секунд / 3 минуты)
- Логирование каждые 10 секунд
- Полный лог каждые 30 секунд

---

#### 5. `fix_result_image_orientation(image_url: str) -> str`
**Назначение:** Скачивает сгенерированное изображение, поворачивает на 90° вправо, загружает обратно

**Логика:**
```python
# 1. Скачиваем изображение
response = requests.get(image_url, timeout=30)
image_data = response.content

# 2. Открываем в PIL
image = Image.open(io.BytesIO(image_data))

# 3. Поворачиваем на 90° ВПРАВО (по часовой)
rotated_image = image.rotate(-90, expand=True)  # -90 = вправо

# 4. Конвертируем обратно в bytes (JPEG, качество 95%)
output = io.BytesIO()
rotated_image.save(output, format='JPEG', quality=95, optimize=True)
fixed_data = output.read()

# 5. Загружаем на Imgur
fixed_url = upload_image_to_imgur(fixed_data)
return fixed_url
```

**Зачем:** NanoBanana иногда возвращает изображения с неправильной ориентацией (повернутые на 90° влево). Принудительный поворот исправляет это.

---

#### 6. `upload_image_temp(image_data: bytes) -> str`
**Назначение:** Обертка для загрузки оригинального фото пользователя

```python
def upload_image_temp(image_data: bytes) -> str:
    # Просто вызываем upload_image_to_imgur
    # (в будущем можно добавить локальное сохранение)
    return upload_image_to_imgur(image_data)
```

---

#### 7. `generate_outfit_image(original_image_data: bytes, recommendations: list, style: str) -> str`
**Назначение:** Главная функция генерации изображения (координирует все шаги)

```python
def generate_outfit_image(original_image_data, recommendations, style):
    try:
        # 1. Загружаем оригинал на Imgur
        image_url = upload_image_temp(original_image_data)
        
        if not image_url:
            return None
        
        # 2. Генерируем через NanoBanana
        result_url = generate_outfit_image_nanobanana(
            image_url, 
            recommendations, 
            style
        )
        
        return result_url
        
    except Exception as e:
        print(f"❌ Ошибка генерации: {str(e)}")
        return None
```

---

### Главный endpoint: POST /api/analyze

```python
@app.post("/api/analyze")
async def analyze_image(
    image: UploadFile = File(...),
    style: str = Form(...)
):
    try:
        # 1. Читаем файл
        image_data = await image.read()
        
        # 2. Валидация размера (макс 10MB)
        if len(image_data) > 10 * 1024 * 1024:
            raise HTTPException(400, "Файл слишком большой")
        
        # 3. Валидация формата
        if image.content_type not in ["image/jpeg", "image/png", "image/webp"]:
            raise HTTPException(400, "Неподдерживаемый формат")
        
        # 4. Загружаем на Imgur (с исправлением ориентации)
        image_url = upload_image_temp(image_data)
        
        # 5. Анализируем через GPT-4o
        analysis_result = analyze_image_and_style(image_url, style)
        
        # 6. Генерируем изображение через NanoBanana
        generated_image_url = generate_outfit_image(
            image_data, 
            analysis_result["recommendations"], 
            style
        )
        
        # 7. Формируем ответ
        return {
            "analysis": analysis_result["analysis"],
            "recommendations": analysis_result["recommendations"],
            "style_tips": analysis_result["style_tips"],
            "generated_image": generated_image_url  # может быть None
        }
        
    except Exception as e:
        raise HTTPException(500, str(e))
```

**Время выполнения:**
- Загрузка на Imgur: ~1-2 сек
- GPT-4o анализ: ~5-10 сек
- NanoBanana генерация: ~60-120 сек
- **Итого: 1-2.5 минуты**

---

## 🌐 Интеграция с внешними API

### OpenAI GPT-4o Vision API

**Endpoint:** `https://api.openai.com/v1/chat/completions`

**Формат запроса:**
```json
{
  "model": "gpt-4o",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "промпт с инструкциями"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "https://i.imgur.com/xxx.jpg"
          }
        }
      ]
    }
  ],
  "max_tokens": 2000
}
```

**Формат ответа:**
```json
{
  "choices": [
    {
      "message": {
        "content": "```json\n{\"analysis\": \"...\", ...}\n```"
      }
    }
  ]
}
```

**Обработка:**
1. Парсим JSON из markdown блока
2. Валидируем структуру
3. Добавляем ссылки на магазины
4. Возвращаем

---

### NanoBanana API

**Создание задачи:**
```
POST https://api.nanobananaapi.ai/api/v1/nanobanana/generate
Authorization: Bearer {API_KEY}

{
  "prompt": "...",
  "type": "IMAGETOIAMGE",
  "imageUrls": ["https://..."],
  "numImages": 1,
  "image_size": "4:3",
  "callBackUrl": "https://..."
}

Ответ:
{
  "code": 200,
  "data": {
    "taskId": "abc-123-def"
  }
}
```

**Проверка статуса:**
```
GET https://api.nanobananaapi.ai/api/v1/nanobanana/record-info?taskId={taskId}
Authorization: Bearer {API_KEY}

Ответ:
{
  "code": 200,
  "data": {
    "successFlag": 1,  // 0=processing, 1=success, 2/3=failed
    "response": {
      "resultImageUrl": "https://..."
    }
  }
}
```

**Поля successFlag:**
- `0` - генерация в процессе
- `1` - успешно завершено
- `2` - ошибка создания задачи
- `3` - ошибка генерации

---

### Imgur API

**Загрузка изображения:**
```
POST https://api.imgur.com/3/image
Authorization: Client-ID 546c25a59c58ad7

{
  "image": "base64_encoded_data",
  "type": "base64"
}

Ответ:
{
  "success": true,
  "data": {
    "link": "https://i.imgur.com/xxx.jpg"
  }
}
```

**Особенности:**
- Анонимная загрузка (не требует регистрации)
- Публичный Client-ID
- Автоматическое преобразование в HTTPS
- Ограничение: ~50 загрузок/час с одного IP

---

## 🖼️ Обработка изображений

### Цепочка преобразований

```
Оригинальное фото пользователя
         │
         ├─→ fix_image_orientation()
         │   └─→ Читает EXIF Orientation (tag 274)
         │   └─→ Поворачивает если нужно
         │   └─→ Удаляет EXIF данные
         │
         ├─→ upload_image_to_imgur()
         │   └─→ Конвертирует в base64
         │   └─→ Загружает через Imgur API
         │   └─→ Получает HTTPS URL
         │
         ├─→ GPT-4o Vision
         │   └─→ Анализирует внешность
         │   └─→ Генерирует рекомендации
         │
         ├─→ NanoBanana API
         │   └─→ Берет Imgur URL
         │   └─→ Генерирует новое фото (1-2 минуты)
         │   └─→ Возвращает URL результата
         │
         ├─→ fix_result_image_orientation()
         │   └─→ Скачивает с NanoBanana
         │   └─→ Поворачивает на 90° вправо
         │   └─→ Загружает обратно на Imgur
         │
         └─→ Финальный HTTPS URL для frontend
```

### Форматы изображений

**Входные форматы (принимаются):**
- JPEG / JPG
- PNG
- WebP

**Выходной формат (всегда):**
- JPEG с качеством 95%

**Ориентация:**
- Исправляется на основе EXIF
- Принудительный поворот на 90° для результата NanoBanana

---

## ❌ Обработка ошибок

### Frontend (Results.js)

**Ошибка загрузки изображения:**
```javascript
<img 
  src={generated_image}
  onError={() => setImageError(true)}
  crossOrigin="anonymous"
/>

{imageError && (
  <div className="image-error">
    <p>⚠️ Изображение не загрузилось</p>
    <p>Возможно, Imgur заблокирован провайдером</p>
    <a href={generated_image}>Открыть напрямую</a>
  </div>
)}
```

**Причины ошибок:**
1. Imgur заблокирован провайдером/страной
2. Mixed Content (HTTP на HTTPS сайте)
3. CORS проблемы
4. Медленное соединение (timeout)

**Решения:**
- `crossOrigin="anonymous"` для CORS
- Принудительное HTTPS
- Fallback кнопка для прямого открытия

---

### Backend (main.py)

**1. Ошибки OpenAI:**
```python
try:
    response = client.chat.completions.create(...)
    
    # Проверка пустого ответа
    if not response.choices:
        raise ValueError("Empty OpenAI response")
    
    content = response.choices[0].message.content
    if not content:
        raise ValueError("Empty content")
    
except openai.APIError as e:
    print(f"❌ OpenAI API error: {e}")
    raise HTTPException(502, "AI service unavailable")
```

**2. Ошибки NanoBanana:**
```python
# Проверка HTTP статуса
if response.status_code != 200:
    print(f"❌ NanoBanana HTTP {response.status_code}")
    return None

# Проверка successFlag
if success_flag in [2, 3]:
    error_msg = task_data.get("errorMessage", "Unknown")
    print(f"❌ Generation failed: {error_msg}")
    return None

# Timeout
if attempt >= max_attempts:
    print(f"⏰ Timeout after {max_attempts * 2} seconds")
    return None
```

**3. Ошибки Imgur:**
```python
try:
    response = requests.post(url, ...)
    
    if response.status_code != 200:
        print(f"❌ Imgur error: {response.status_code}")
        return None
    
    if not result.get("success"):
        print(f"❌ Imgur failed: {result}")
        return None
        
except requests.exceptions.Timeout:
    print("❌ Imgur timeout")
    return None
```

**4. Graceful Degradation:**
```python
# Если генерация изображения не удалась
generated_image_url = generate_outfit_image(...)

# Всё равно возвращаем рекомендации (без изображения)
return {
    "analysis": analysis_result["analysis"],
    "recommendations": analysis_result["recommendations"],
    "style_tips": analysis_result["style_tips"],
    "generated_image": generated_image_url  # может быть None
}
```

Frontend проверяет `if (generated_image)` перед отображением.

---

## 🔐 Безопасность и лимиты

### Валидация на Backend

```python
# Размер файла
if len(image_data) > 10 * 1024 * 1024:  # 10MB
    raise HTTPException(400, "Файл слишком большой")

# Формат файла
allowed_types = ["image/jpeg", "image/png", "image/webp"]
if image.content_type not in allowed_types:
    raise HTTPException(400, "Неподдерживаемый формат")

# Валидация стиля
allowed_styles = ["Casual", "Business", "Sport", "Evening", ...]
if style not in allowed_styles:
    raise HTTPException(400, "Неизвестный стиль")
```

### CORS настройки

**Development (локально):**
```python
allow_origins=["http://localhost:3000"]
```

**Production (Railway):**
```python
allow_origins=["https://dependable-joy-production.up.railway.app"]
```

### API ключи (переменные окружения)

```bash
# Backend .env
OPENAI_API_KEY=sk-proj-...
NANOBANANA_API_KEY=187db...
IMGUR_CLIENT_ID=546c25a59c58ad7  # опционально
HOST=0.0.0.0
PORT=8000
ALLOWED_ORIGINS=https://...

# Frontend .env
REACT_APP_API_URL=https://odezda-production.up.railway.app
```

### Таймауты

```python
# OpenAI
response = client.chat.completions.create(...)  # ~10 сек

# NanoBanana создание задачи
requests.post(..., timeout=30)  # 30 сек

# NanoBanana polling
max_attempts = 90  # 90 * 2 = 180 сек = 3 минуты

# Imgur загрузка
requests.post(..., timeout=30)  # 30 сек

# Frontend Axios
axios.post(..., { timeout: 200000 })  # 200 сек
```

---

## 📊 Производительность и оптимизация

### Кэширование (будущее улучшение)

**Идея:** Кэшировать результаты GPT-4o для одинаковых фото+стиль

```python
# Redis или in-memory cache
cache_key = f"{hash(image_data)}:{style}"
if cache_key in cache:
    return cache[cache_key]

result = analyze_image_and_style(...)
cache[cache_key] = result
return result
```

### Параллелизация (будущее улучшение)

**Текущая схема (последовательная):**
```
Imgur → GPT-4o → NanoBanana → Imgur
1-2сек   5-10сек   60-120сек   1-2сек
```

**Оптимизированная схема (параллельная):**
```
Imgur → ┬→ GPT-4o (5-10сек)
        └→ NanoBanana (60-120сек, начать сразу с базовым промптом)
```

Можно запустить NanoBanana сразу с общим промптом стиля, пока GPT-4o думает.

### CDN для изображений

Использовать Cloudinary или AWS CloudFront вместо Imgur:
- Быстрее загрузка
- Надежнее
- Автоматическая оптимизация
- Не блокируется провайдерами

---

## 🚀 Деплой на Railway

### Структура проекта на Railway

```
Railway Project: odezda
├── Backend Service
│   ├── Root Directory: . (корень репозитория)
│   ├── Start Command: python main.py
│   ├── Port: $PORT (автоматически)
│   ├── Variables:
│   │   ├── OPENAI_API_KEY
│   │   ├── NANOBANANA_API_KEY
│   │   ├── HOST=0.0.0.0
│   │   ├── PORT=$PORT
│   │   └── ALLOWED_ORIGINS=https://frontend-url
│   └── Domain: https://odezda-production.up.railway.app
│
└── Frontend Service
    ├── Root Directory: frontend
    ├── Build Command: npm run build (автоматически)
    ├── Start Command: caddy (автоматически)
    ├── Variables:
    │   └── REACT_APP_API_URL=https://odezda-production.up.railway.app
    └── Domain: https://dependable-joy-production.up.railway.app
```

### CI/CD Pipeline

```
GitHub Push
     │
     ├─→ Railway Webhook
     │
     ├─→ Backend Service
     │   ├─→ Pull latest code
     │   ├─→ Install dependencies (pip)
     │   ├─→ Start uvicorn
     │   └─→ Health check
     │
     └─→ Frontend Service
         ├─→ Pull latest code
         ├─→ Install dependencies (npm ci)
         ├─→ Build React app (npm run build)
         ├─→ Serve via Caddy
         └─→ Health check
```

**Время деплоя:**
- Backend: ~2 минуты
- Frontend: ~3 минуты

---

## 📈 Метрики и мониторинг

### Логирование на Backend

```python
# Каждый запрос логируется:
print(f"📷 Получено изображение: {len(image_data)} байт")
print(f"🎨 Выбран стиль: {style}")
print(f"🚀 Отправка в OpenAI GPT-4o...")
print(f"✅ GPT-4o ответил за {time_elapsed}сек")
print(f"🚀 Отправка в NanoBanana API...")
print(f"⏳ Статус генерации: {success_flag}")
print(f"✅ Изображение готово за {time_elapsed}сек")
```

### Railway Logs

Доступ к логам:
```
Railway Dashboard → Service → Logs (вкладка)
```

Видны:
- HTTP запросы
- Ошибки
- Время выполнения
- API вызовы

---

## 🔮 Будущие улучшения

### 1. Кэширование результатов
- Redis для кэша анализа GPT-4o
- Сокращение времени повторных запросов
- Экономия API кредитов

### 2. Очередь задач
- Celery + Redis для асинхронной обработки
- Пользователь получает task_id
- Polling статуса через WebSocket или SSE

### 3. База данных
- PostgreSQL для хранения истории
- Профили пользователей
- Сохраненные рекомендации

### 4. Аутентификация
- OAuth (Google, VK)
- История запросов для каждого пользователя
- Лимиты на количество запросов

### 5. Улучшенная генерация
- Попробовать другие модели (SDXL, Midjourney API)
- Тонкая настройка промптов
- Multiple варианты изображений

### 6. Mobile App
- React Native приложение
- Нативная обработка фото
- Push уведомления о готовности

---

## 📚 Документация API

### POST /api/analyze

**Запрос:**
```
POST /api/analyze
Content-Type: multipart/form-data

Form Fields:
- image: File (JPEG/PNG/WebP, макс 10MB)
- style: String (один из предопределенных стилей)
```

**Ответ (успех):**
```json
{
  "analysis": "Описание внешности человека...",
  "recommendations": [
    {
      "item": "Black blazer",
      "description": "Черный приталенный пиджак...",
      "why": "Подчеркивает фигуру...",
      "search_query": "черный пиджак женский",
      "shop_links": [
        {
          "name": "Lamoda",
          "url": "https://..."
        }
      ]
    }
  ],
  "style_tips": [
    "Совет 1",
    "Совет 2"
  ],
  "generated_image": "https://i.imgur.com/xxx.jpg"
}
```

**Ответ (ошибка):**
```json
{
  "detail": "Сообщение об ошибке"
}
```

**HTTP коды:**
- 200 - успешно
- 400 - неверный запрос (формат, размер)
- 500 - внутренняя ошибка сервера
- 502 - ошибка внешнего API (OpenAI, NanoBanana)

---

## 🎓 Заключение

Проект **Odezda AI** представляет собой полнофункциональное веб-приложение для AI-анализа внешности и подбора одежды с визуализацией.

**Ключевые особенности:**
- ✅ Полный цикл от загрузки фото до готовых рекомендаций
- ✅ Интеграция 3 внешних API (OpenAI, NanoBanana, Imgur)
- ✅ Адаптивный дизайн для desktop и mobile
- ✅ Обработка ошибок и fallback механизмы
- ✅ Деплой на Railway с CI/CD через GitHub
- ✅ Продакшн-ready код с логированием и валидацией

**Технологии:**
- Frontend: React, Axios, CSS3
- Backend: Python, FastAPI, Uvicorn
- AI: OpenAI GPT-4o Vision, NanoBanana
- Storage: Imgur
- Deploy: Railway, GitHub

**Время обработки:** ~1-2.5 минуты на запрос

**Стоимость:**
- OpenAI GPT-4o: ~$0.01-0.02 за запрос
- NanoBanana: зависит от тарифа
- Imgur: бесплатно
- Railway: $5/месяц базовый план

---

📝 **Документ создан:** 2025-11-12  
🔄 **Версия:** 1.0  
👨‍💻 **Автор:** Odezda AI Team

