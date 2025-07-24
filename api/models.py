from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class Item(BaseModel):
    """
    Pydantic-модель для объекта Item.
    Определяет структуру данных, выполняет валидацию и сериализацию.
    """
    id: Optional[str] = Field(
        default=None,
        description="Уникальный идентификатор. Генерируется сервером, если не передан."
    )
    name: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Название предмета. Обязательное поле."
    )
    description: Optional[str] = Field(
        default=None,
        max_length=500,
        description="Дополнительное описание предмета."
    )
    timestamp: Optional[str] = Field(
        default=None,
        description="ISO‑строка времени создания в UTC. Генерируется сервером, если не передан."
    )

    class Config:
        schema_extra = {
            "example": {
                "name": "Test Item",
                "description": "Это тестовый предмет"
            }
        }
