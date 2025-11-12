import os
import base64
import time
import requests
from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from dotenv import load_dotenv
from openai import OpenAI
from PIL import Image
import io
from typing import Optional

# Загружаем переменные окружения
load_dotenv()

app = FastAPI(title="Odezda AI API")

# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Инициализация OpenAI клиента
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Создаем директорию для временных файлов
os.makedirs("uploads", exist_ok=True)

# Монтируем папку uploads для доступа к файлам
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


def analyze_image_and_style(image_data: bytes, style: str) -> dict:
    """
    Анализирует фото пользователя и подбирает одежду в указанном стиле
    """
    try:
        # Конвертируем изображение в base64
        base64_image = base64.b64encode(image_data).decode('utf-8')
        
        # Создаем промпт для анализа
        prompt = f"""Проанализируй это фото человека и подбери одежду в стиле "{style}".

Верни ответ в формате JSON со следующими полями:
1. "analysis": краткий анализ внешности человека (тип фигуры, цвет кожи, волос)
2. "person_description": детальное описание внешности для генерации изображения (пол, возраст, цвет волос, телосложение, черты лица) - на английском
3. "outfit_description": детальное описание полного образа одежды в выбранном стиле (на английском)
4. "recommendations": массив из 5-7 рекомендаций одежды, каждая с полями:
   - "item": название предмета одежды (на русском)
   - "description": описание (цвет, материал, особенности)
   - "why": почему это подходит человеку и стилю
   - "search_query": поисковый запрос для поиска товара (НА РУССКОМ ЯЗЫКЕ! Например: "черное пальто женское", "синие джинсы мужские")
5. "style_tips": 3-5 общих советов по стилю

Стиль должен соответствовать: {style}"""

        # Отправляем запрос к OpenAI
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": prompt},
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/jpeg;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            max_tokens=2000,
            response_format={"type": "json_object"}
        )
        
        # Парсим ответ
        import json
        
        # Проверяем что ответ не пустой
        if not response.choices or not response.choices[0].message.content:
            raise HTTPException(status_code=500, detail="OpenAI вернул пустой ответ. Попробуйте еще раз.")
        
        content = response.choices[0].message.content
        
        try:
            result = json.loads(content)
        except json.JSONDecodeError as e:
            print(f"Ошибка парсинга JSON: {content}")
            raise HTTPException(status_code=500, detail=f"Ошибка обработки ответа AI: {str(e)}")
        
        return result
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка анализа: {str(e)}")


def fix_image_orientation(image_data: bytes) -> bytes:
    """
    Исправляет ориентацию изображения согласно EXIF данным
    """
    try:
        from PIL import Image, ImageOps
        import io
        
        # Открываем изображение
        image = Image.open(io.BytesIO(image_data))
        
        # Проверяем EXIF данные
        try:
            # ImageOps.exif_transpose автоматически поворачивает изображение по EXIF
            image = ImageOps.exif_transpose(image)
            print("🔄 Исправлена ориентация изображения по EXIF")
        except Exception as exif_error:
            # Если нет EXIF или ошибка - оставляем как есть
            print(f"ℹ️ EXIF ориентация не найдена или не требует исправления")
        
        # Конвертируем обратно в bytes
        output = io.BytesIO()
        # Сохраняем в JPEG с хорошим качеством, без EXIF данных
        image.save(output, format='JPEG', quality=95, optimize=True)
        output.seek(0)
        
        return output.read()
        
    except Exception as e:
        print(f"⚠️ Не удалось исправить ориентацию: {str(e)}, использую оригинал")
        return image_data


def fix_result_image_orientation(image_url: str) -> str:
    """
    Скачивает сгенерированное изображение, поворачивает на 90° вправо и загружает обратно
    """
    try:
        from PIL import Image
        import io
        
        print(f"📥 Скачиваю изображение с {image_url[:50]}...")
        
        # Скачиваем изображение
        response = requests.get(image_url, timeout=30)
        if response.status_code != 200:
            print(f"❌ Не удалось скачать изображение: HTTP {response.status_code}")
            return None
        
        image_data = response.content
        print(f"✅ Изображение скачано ({len(image_data)} байт)")
        
        # Открываем изображение
        image = Image.open(io.BytesIO(image_data))
        
        # ПОВОРАЧИВАЕМ НА 90° ВПРАВО (по часовой стрелке)
        print(f"🔄 Поворачиваю изображение на 90° вправо...")
        rotated_image = image.rotate(-90, expand=True)  # -90 = вправо, expand=True чтобы не обрезать
        
        # Конвертируем в bytes
        output = io.BytesIO()
        rotated_image.save(output, format='JPEG', quality=95, optimize=True)
        output.seek(0)
        fixed_data = output.read()
        
        # Загружаем повернутое изображение на Imgur
        print(f"📤 Загружаю повернутое изображение на Imgur...")
        fixed_url = upload_image_to_imgur(fixed_data)
        
        if fixed_url:
            return fixed_url
        else:
            return None
            
    except Exception as e:
        print(f"❌ Ошибка при повороте изображения: {str(e)}")
        return None


def upload_image_to_imgur(image_data: bytes) -> str:
    """
    Загружает изображение на Imgur и возвращает публичный URL
    """
    try:
        import base64
        
        # ИСПРАВЛЯЕМ ОРИЕНТАЦИЮ перед загрузкой!
        image_data = fix_image_orientation(image_data)
        
        # Imgur API (анонимная загрузка, без регистрации)
        url = "https://api.imgur.com/3/image"
        
        headers = {
            "Authorization": "Client-ID 546c25a59c58ad7"  # Публичный Client ID
        }
        
        # Конвертируем в base64
        image_b64 = base64.b64encode(image_data).decode('utf-8')
        
        data = {
            "image": image_b64,
            "type": "base64"
        }
        
        print("📤 Загрузка изображения на Imgur...")
        response = requests.post(url, headers=headers, data=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            if result.get("success"):
                image_url = result["data"]["link"]
                print(f"✅ Изображение загружено: {image_url[:60]}...")
                return image_url
            else:
                print(f"❌ Imgur вернул ошибку: {result}")
                return None
        else:
            print(f"❌ Ошибка загрузки на Imgur: {response.status_code}")
            print(f"📄 Ответ: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Ошибка загрузки на Imgur: {str(e)}")
        return None


def upload_image_temp(image_data: bytes) -> str:
    """
    Сохраняет изображение локально И загружает на Imgur для публичного доступа
    """
    try:
        # Сохраняем локально для резервной копии
        timestamp = int(time.time())
        filename = f"temp_{timestamp}.jpg"
        filepath = f"uploads/{filename}"
        
        with open(filepath, 'wb') as f:
            f.write(image_data)
        
        print(f"💾 Изображение сохранено локально: {filename}")
        
        # Загружаем на Imgur для публичного доступа
        public_url = upload_image_to_imgur(image_data)
        
        if public_url:
            return public_url
        else:
            print("⚠️ Не удалось загрузить на Imgur, используем localhost (может не работать)")
            return f"http://localhost:8000/uploads/{filename}"
            
    except Exception as e:
        print(f"❌ Ошибка сохранения изображения: {str(e)}")
        return None


def generate_outfit_image_nanobanana(image_url: str, recommendations: list, style: str) -> str:
    """
    Генерирует изображение с новой одеждой используя NanoBanana API
    Использует конкретные вещи из recommendations для точности
    """
    try:
        api_key = os.getenv("NANOBANANA_API_KEY")
        if not api_key:
            print("❌ NanoBanana API ключ не найден в .env")
            return None
        
        url = "https://api.nanobananaapi.ai/api/v1/nanobanana/generate"
        
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
        # Создаем детальный промпт из конкретных вещей recommendations
        clothing_items = []
        for rec in recommendations[:5]:  # Берем первые 5 вещей
            item_name = rec.get("item", "")
            description = rec.get("description", "")
            clothing_items.append(f"{item_name} ({description})")
        
        clothing_list = ", ".join(clothing_items)
        
        prompt = f"""Change the person's clothing to exactly these items: {clothing_list}.
Keep the person's face, body shape, skin tone, hair, and overall identity completely unchanged. 
Only modify the clothing items to match the specified outfit. 
Style: {style}.
Maintain photorealistic quality and natural lighting."""
        
        data = {
            "prompt": prompt,
            "type": "IMAGETOIAMGE",
            "imageUrls": [image_url],
            "numImages": 1,
            "image_size": "4:3",  # Горизонтальный формат
            "callBackUrl": "https://nanobanana-callback.example.com/webhook"  # Обязательный параметр
        }
        
        print(f"\n🚀 Отправка запроса в NanoBanana API...")
        print(f"📷 URL изображения: {image_url}")
        print(f"👕 Конкретные вещи из рекомендаций:")
        for item in clothing_items:
            print(f"   - {item}")
        print(f"🎨 Стиль: {style}")
        
        response = requests.post(url, headers=headers, json=data, timeout=30)
        
        if response.status_code == 200:
            result = response.json()
            print(f"📦 Полный ответ API: {result}")
            
            # Проверяем код ответа в теле
            response_code = result.get("code")
            if response_code != 200:
                error_msg = result.get("msg", "Unknown error")
                print(f"❌ API вернул ошибку (code {response_code}): {error_msg}")
                return None
            
            task_id = result.get("data", {}).get("taskId")
            
            if not task_id:
                print(f"❌ Не получен taskId: {result}")
                return None
            
            print(f"✅ Задача создана! ID: {task_id}")
            print(f"⏳ Ожидание обработки (может занять до 3 минут)...")
            print(f"🔗 Проверить статус можно на: https://nanobananaapi.ai/dashboard/tasks")
            
            # Polling результата - правильный endpoint!
            max_attempts = 90  # 90 попыток по 2 секунды = 180 секунд (3 минуты)
            for attempt in range(max_attempts):
                time.sleep(2)
                
                # ПРАВИЛЬНЫЙ endpoint с query параметром!
                status_url = f"https://api.nanobananaapi.ai/api/v1/nanobanana/record-info?taskId={task_id}"
                
                try:
                    status_response = requests.get(
                        status_url, 
                        headers={"Authorization": f"Bearer {api_key}"},
                        timeout=10
                    )
                except requests.exceptions.Timeout:
                    print(f"⏱️ Таймаут при проверке статуса (попытка {attempt + 1}), повторяю...")
                    continue
                
                if status_response.status_code == 200:
                    status_data = status_response.json()
                    
                    # Логируем полный ответ каждые 30 секунд для отладки
                    if attempt % 15 == 0 or attempt == 0:
                        print(f"\n📊 Полный ответ статуса (попытка {attempt + 1}/{max_attempts}):")
                        print(f"   {status_data}")
                    
                    # Проверяем код ответа в теле
                    response_code = status_data.get("code")
                    if response_code == 404:
                        # Задача еще не найдена, продолжаем ждать
                        if attempt % 10 == 0:
                            print(f"⏳ Задача еще не найдена в системе, ожидаю...")
                        continue
                    elif response_code and response_code != 200:
                        error_msg = status_data.get("msg", "Unknown error")
                        print(f"❌ API вернул ошибку при проверке статуса (code {response_code}): {error_msg}")
                        print(f"📄 Детали: {status_data}")
                        return None
                    
                    # Получаем данные задачи
                    task_data = status_data.get("data", {})
                    
                    # successFlag: 0-generating, 1-success, 2-create task failed, 3-generation failed
                    success_flag = task_data.get("successFlag")
                    error_message = task_data.get("errorMessage", "")
                    
                    # Выводим статус каждые 10 секунд
                    if attempt % 5 == 0:
                        status_text = {
                            0: "GENERATING",
                            1: "SUCCESS",
                            2: "CREATE_TASK_FAILED",
                            3: "GENERATION_FAILED"
                        }.get(success_flag, f"UNKNOWN({success_flag})")
                        print(f"⏳ Статус: {status_text} (попытка {attempt + 1}/{max_attempts}, {attempt * 2}сек)")
                    
                    # Проверяем статус по successFlag
                    if success_flag == 1:  # SUCCESS
                        # Получаем URL из response
                        response_obj = task_data.get("response", {})
                        result_url = response_obj.get("resultImageUrl") or response_obj.get("originImageUrl")
                        
                        if result_url:
                            print(f"\n🎉 Изображение готово!")
                            print(f"🔗 Оригинальный URL: {result_url[:60]}...")
                            
                            # ПОВОРАЧИВАЕМ изображение на 90° вправо!
                            print(f"🔄 Скачиваю и поворачиваю изображение...")
                            fixed_url = fix_result_image_orientation(result_url)
                            
                            if fixed_url:
                                print(f"✅ Изображение повернуто!")
                                print(f"🔗 Финальный URL: {fixed_url[:60]}...")
                                return fixed_url
                            else:
                                print(f"⚠️ Не удалось повернуть, использую оригинал")
                                return result_url
                        else:
                            print(f"\n❌ Задача завершена успешно но URL изображения не найден")
                            print(f"📄 Полный ответ: {status_data}")
                            return None
                    
                    elif success_flag == 2 or success_flag == 3:  # FAILED
                        print(f"\n❌ Задача завершилась с ошибкой (flag={success_flag})")
                        if error_message:
                            print(f"💬 Сообщение: {error_message}")
                        print(f"📄 Детали: {status_data}")
                        return None
                    
                    elif success_flag == 0:  # GENERATING
                        # Задача еще обрабатывается, продолжаем ждать
                        continue
                    
                    else:
                        # Неизвестный successFlag
                        if attempt % 10 == 0:
                            print(f"⚠️ Неизвестный successFlag: {success_flag}")
                            print(f"📄 Продолжаю ждать... (попытка {attempt + 1}/{max_attempts})")
                        continue
                else:
                    print(f"❌ HTTP ошибка при проверке статуса: {status_response.status_code}")
                    if attempt % 10 == 0:
                        print(f"📄 Ответ: {status_response.text[:200]}")
            
            print(f"\n⏰ Превышено время ожидания ({max_attempts * 2} секунд)")
            print(f"💡 Проверьте результат вручную: https://nanobananaapi.ai/dashboard/tasks")
            print(f"🆔 Task ID: {task_id}")
            return None
        
        else:
            print(f"❌ Ошибка NanoBanana API: {response.status_code}")
            print(f"📄 Ответ: {response.text}")
            return None
    
    except requests.exceptions.Timeout:
        print("❌ Превышено время ожидания запроса")
        return None
    except Exception as e:
        print(f"❌ Ошибка генерации через NanoBanana: {str(e)}")
        return None


def generate_outfit_image(person_description: str, recommendations: list, style: str, original_image_data: bytes = None) -> str:
    """
    Генерирует изображение человека в конкретных рекомендованных вещах используя NanoBanana API
    """
    try:
        if not original_image_data:
            print("⚠️ Оригинальное фото не передано")
            return None
        
        if not recommendations:
            print("⚠️ Рекомендации одежды отсутствуют")
            return None
        
        # Загружаем оригинальное фото и получаем URL
        print("📤 Загрузка оригинального изображения...")
        image_url = upload_image_temp(original_image_data)
        
        if not image_url:
            print("❌ Не удалось загрузить изображение")
            return None
        
        # Генерируем через NanoBanana используя конкретные рекомендации!
        return generate_outfit_image_nanobanana(image_url, recommendations, style)
        
    except Exception as e:
        print(f"❌ Ошибка генерации: {str(e)}")
        return None


def search_products(search_query: str) -> list:
    """
    Поиск товаров по запросу (заглушка для демонстрации)
    В реальном проекте здесь будет интеграция с API магазинов
    """
    from urllib.parse import quote
    
    # Кодируем запрос для URL (русские символы → %D0%A7%D0%B5%D1%80%D0%BD%D0%BE%D0%B5...)
    encoded_query = quote(search_query)
    
    # Генерируем ссылки на товары с закодированным запросом
    base_urls = [
        f"https://www.lamoda.ru/catalogsearch/result/?q={encoded_query}",
        f"https://www.wildberries.ru/catalog/0/search.aspx?search={encoded_query}",
        f"https://www.ozon.ru/search/?text={encoded_query}",
    ]
    
    return [
        {"name": "Lamoda", "url": base_urls[0]},
        {"name": "Wildberries", "url": base_urls[1]},
        {"name": "Ozon", "url": base_urls[2]},
    ]


@app.get("/")
async def root():
    return {"message": "Odezda AI API работает!"}


@app.post("/api/analyze")
async def analyze_photo(
    photo: UploadFile = File(...),
    style: str = Form(...)
):
    """
    Анализирует фото и подбирает одежду в указанном стиле
    """
    try:
        # Проверяем, что файл - изображение
        if not photo.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Файл должен быть изображением")
        
        # Читаем файл
        image_data = await photo.read()
        
        # Проверяем размер (макс 10MB)
        if len(image_data) > 10 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Файл слишком большой (макс 10MB)")
        
        # Проверяем, что это валидное изображение
        try:
            img = Image.open(io.BytesIO(image_data))
            # Оптимизируем размер если нужно
            if img.width > 1024 or img.height > 1024:
                img.thumbnail((1024, 1024))
                buffer = io.BytesIO()
                img.save(buffer, format=img.format or "JPEG")
                image_data = buffer.getvalue()
        except Exception as e:
            raise HTTPException(status_code=400, detail="Невалидное изображение")
        
        # Анализируем фото и стиль
        analysis_result = analyze_image_and_style(image_data, style)
        
        # Добавляем ссылки на товары для каждой рекомендации
        for recommendation in analysis_result.get("recommendations", []):
            search_query = recommendation.get("search_query", "")
            recommendation["shop_links"] = search_products(search_query)
        
        # Генерируем изображение с одеждой используя NanoBanana (сохраняет ваше лицо!)
        generated_image_url = None
        if "recommendations" in analysis_result and analysis_result["recommendations"]:
            print("\n" + "="*80)
            print("🎨 ЗАПУСК ГЕНЕРАЦИИ ИЗОБРАЖЕНИЯ С NANOBANANA API")
            print("="*80)
            
            generated_image_url = generate_outfit_image(
                analysis_result.get("person_description", ""),
                analysis_result["recommendations"],  # Передаем конкретные рекомендации!
                style,
                original_image_data=image_data  # Передаем оригинальное фото!
            )
            
            if generated_image_url:
                analysis_result["generated_image"] = generated_image_url
                print("\n" + "="*80)
                print("✅ УСПЕХ! Изображение добавлено в результаты")
                print(f"🔗 URL: {generated_image_url}")
                print("="*80 + "\n")
            else:
                print("\n" + "="*80)
                print("⚠️ ПРЕДУПРЕЖДЕНИЕ: Изображение не было получено")
                print("💡 Возможные причины:")
                print("   - Превышено время ожидания (проверьте вручную на сайте)")
                print("   - Ошибка при обработке")
                print("   - Недостаточно кредитов")
                print("📊 Анализ одежды продолжается без изображения...")
                print("="*80 + "\n")
        
        return JSONResponse(content={
            "success": True,
            "data": analysis_result
        })
        
    except HTTPException as he:
        raise he
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка сервера: {str(e)}")


@app.get("/api/health")
async def health_check():
    """Проверка работоспособности API"""
    return {
        "status": "healthy",
        "openai_configured": bool(os.getenv("OPENAI_API_KEY"))
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    host = os.getenv("HOST", "0.0.0.0")
    uvicorn.run(app, host=host, port=port)


