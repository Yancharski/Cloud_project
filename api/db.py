import os
from dotenv import load_dotenv
import boto3
from boto3.dynamodb.conditions import Key

# Загрузка переменных окружения из .env
load_dotenv()

# Чтение настроек
TABLE_NAME = os.getenv("DYNAMODB_TABLE", "items")
REGION = os.getenv("AWS_REGION", "us-east-1")
ENDPOINT_URL = os.getenv("DYNAMODB_ENDPOINT_URL")  # используется для LocalStack

# Инициализация ресурса DynamoDB
# Если ENDPOINT_URL не задан, boto3 подключится к реальной AWS по REGION
dynamodb = boto3.resource(
    "dynamodb",
    region_name=REGION,
    endpoint_url=ENDPOINT_URL or None
)

# Получение объекта таблицы (не создаёт её, ожидает существования)
table = dynamodb.Table(TABLE_NAME)
