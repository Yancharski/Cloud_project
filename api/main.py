from fastapi import FastAPI, HTTPException
from uuid import uuid4
from datetime import datetime
from typing import List, Optional

from .models import Item
from .db import table

app = FastAPI(
    title="Cloud REST API",
    version="1.0",
    description="Простой API для создания и чтения объектов в DynamoDB"
)


@app.post(
    "/items/",
    response_model=Item,
    summary="Создать новый Item",
    description="Принимает JSON с полями name и description, генерирует id и timestamp, сохраняет в DynamoDB и возвращает весь объект."
)
def create_item(item: Item) -> Item:
    # 1. Генерация id и timestamp, если не переданы
    if not item.id:
        item.id = str(uuid4())
    if not item.timestamp:
        # ISO‑формат UTC, чтобы можно было легко сортировать и считывать
        item.timestamp = datetime.utcnow().isoformat()

    # 2. Запись в таблицу DynamoDB
    try:
        table.put_item(Item=item.dict())
    except Exception as e:
        # Возвращаем HTTP 500, если запись не удалась
        raise HTTPException(status_code=500, detail=f"Не удалось сохранить item: {e}")

    # 3. Отдаём сохранённый объект
    return item


@app.get(
    "/items/{item_id}",
    response_model=Item,
    summary="Получить Item по ID",
    description="Ищет в DynamoDB объект с указанным ключом id и возвращает его. Если не найден — отдаёт 404."
)
def get_item(item_id: str) -> Item:
    # 1. Чтение из таблицы по ключу
    try:
        resp = table.get_item(Key={"id": item_id})
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Не удалось прочитать item: {e}")

    # 2. Если в ответе нет поля "Item" — объект не найден
    if "Item" not in resp:
        raise HTTPException(status_code=404, detail="Item не найден")

    # 3. Возвращаем найденный объект
    return Item(**resp["Item"])


@app.get(
    "/items/",
    response_model=List[Item],
    summary="Список всех Items (сканирование)",
    description="Возвращает все объекты из таблицы. Для продакшена стоит ограничить объём или добавить фильтрацию."
)
def list_items(limit: Optional[int] = 100) -> List[Item]:
    # Простой scan: возвращаем первые `limit` элементов
    try:
        resp = table.scan(Limit=limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Не удалось получить список: {e}")

    items = resp.get("Items", [])
    return [Item(**i) for i in items]

from mangum import Mangum

handler = Mangum(app)

