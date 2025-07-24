# Cloud-Based REST API with DynamoDB

Подробная инструкция по установке, настройке и использованию проекта "Cloud-Based REST API with DynamoDB", реализованного на FastAPI и упакованного в AWS Lambda через Terraform. Локальная разработка и тестирование осуществляется через LocalStack.

---

## 📋 Содержание

1. [Описание проекта](#описание-проекта)
2. [Архитектура](#архитектура)
3. [Структура репозитория](#структура-репозитория)
4. [Требования](#требования)
5. [Настройка окружения](#настройка-окружения)

   * [Переменные окружения](#переменные-окружения)
   * [Файл `.env`](#файл-env)
6. [Локальная разработка](#локальная-разработка)

   * [Запуск LocalStack](#запуск-localstack)
   * [Создание таблицы DynamoDB](#создание-таблицы-dynamodb)
   * [Запуск FastAPI](#запуск-fastapi)
   * [Тестирование API](#тестирование-api)
7. [Деплой в AWS](#деплой-в-aws)

   * [Установка Terraform](#установка-terraform)
   * [Инициализация и применение Terraform](#инициализация-и-применение-terraform)
   * [Проверка развертывания](#проверка-развертывания)
8. [Использование API](#использование-api)

   * [Создание элемента](#создание-элемента)
   * [Получение элемента по ID](#получение-элемента-по-id)
   * [Сканирование элементов](#сканирование-элементов)
9. [Дополнительные возможности](#дополнительные-возможности)
10. [CI/CD (опционально)](#cicd-опционально)
11. [Полезные ссылки](#полезные-ссылки)
12. [Лицензия](#лицензия)

---

## Описание проекта

Проект представляет собой **REST API** на **FastAPI**, которое:

* Принимает JSON-запросы на создание нового объекта (Item).
* Сохраняет данные в **DynamoDB**.
* Обеспечивает получение сохранённых объектов по уникальному `id`.

Для локальной разработки используется **LocalStack**, эмулирующий AWS-сервисы. Для продакшн-деплоя используется **AWS Lambda + API Gateway**, конфигурируемые через **Terraform**.

## Архитектура

![Архитектура](./diagram.png)

1. **FastAPI** (`api/main.py`, `api/models.py`, `api/db.py`) — бизнес-логика.
2. **DynamoDB** — хранилище данных (таблица с `hash_key = id`).
3. **LocalStack** — локальная эмуляция AWS (dynamodb, lambda, apigateway, iam, logs).
4. **AWS Lambda** + **API Gateway** — serverless деплой в облако.
5. **Terraform** (`infra/`) — Infrastructure as Code для автоматизации создания ресурсов.

## Структура репозитория

```
Сloud_project/
│
├── api/                   # Исходники FastAPI
│   ├── __init__.py        # Экспорт app
│   ├── main.py            # Маршруты API
│   ├── models.py          # Pydantic-модели
│   └── db.py              # Инициализация DynamoDB
│
├── infra/                 # Terraform-конфигурация
│   ├── main.tf            # Ресурсы AWS
│   ├── variables.tf       # Переменные
│   └── outputs.tf         # Outputs
│
├── localstack/            # Docker-композиция LocalStack
│   └── docker-compose.yml
│
├── .env.example           # Пример файла переменных окружения
├── .gitignore
├── requirements.txt       # Python-зависимости
└── README.md
```

## Требования

* **Docker & Docker Compose**
* **Python 3.9+**
* **Terraform 1.0+**
* AWS CLI (для локальной работы с LocalStack можно использовать `aws --endpoint-url`)

## Настройка окружения

### Переменные окружения

Проект использует файл `.env`, содержащий:

| Переменная              | Описание                                                |
|-------------------------|---------------------------------------------------------|
| `DYNAMODB_TABLE`        | Имя таблицы DynamoDB (по умолчанию `items`)             |
| `AWS_DEFAULT_REGION`    | Регион AWS (по умолчанию `us-east-1`)                   |
| `DYNAMODB_ENDPOINT_URL` | Локальный endpoint (LocalStack) `http://localhost:4566` |
| `AWS_ACCESS_KEY_ID`     | Access Key для AWS или LocalStack                       |
| `AWS_SECRET_ACCESS_KEY` | Secret Key для AWS или LocalStack                       |
| `LOCALSTACK_AUTH_TOKEN` | Токен для аунтефикации c LocalStack                     |

Скопируйте `.env.example` в `.env` и при необходимости скорректируйте значения.

### Файл `.env.example`

```dotenv
# Локальные переменные для LocalStack
LOCALSTACK_AUTH_TOKEN=use token from LocalStack
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_DEFAULT_REGION=us-east-1

# Endpoint for local emulation (LocalStack)
DYNAMODB_ENDPOINT_URL=http://localstack:4566

# Имя таблицы в DynamoDB
DYNAMODB_TABLE=items
```

## Локальная разработка

### Запуск LocalStack

```bash
cd localstack
docker-compose up -d
```

Убедитесь, что контейнер работает:

```bash
docker ps | grep localstack
```

### Создание таблицы DynamoDB

Локально создайте таблицу:

```bash
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --endpoint-url $DYNAMODB_ENDPOINT_URL
```

### Установка зависимостей и запуск FastAPI

```bash
# в корне проекта
pip install -r requirements.txt
uvicorn api:app --reload --host 0.0.0.0 --port 8000
```

Перейдите в браузер: `http://localhost:8000/docs` — Swagger UI.

### Тестирование API

**Создание элемента:**

```bash
curl -X POST http://localhost:8000/items/ \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","description":"Описание"}'
```

**Получение по ID:**

```bash
curl http://localhost:8000/items/<ID>
```

**Сканирование:**

```bash
curl http://localhost:8000/items/?limit=50
```

## Деплой в AWS

### Установка Terraform

[Установка Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install)

### Инициализация и применение Terraform

```bash
cd infra
terraform init
terraform apply -var="env=dev" -auto-approve
```

Terraform создаст:

* DynamoDB Table
* IAM Role & Policies
* Lambda Function
* API Gateway (Stage = `dev`)

### Проверка развертывания

После `apply` вы увидите вывод:

```
Outputs:
  api_url = https://<api_id>.execute-api.us-east-1.amazonaws.com/dev
  dynamodb_table_name = items
  lambda_function_arn = arn:aws:lambda:…
  api_id = <api_id>
```

Сохраните `api_url` и протестируйте аналогично локальной версии.

## Использование API

1. **Создание элемента**

   ```bash
   curl -X POST $API_URL/items/ \
     -H "Content-Type: application/json" \
     -d '{"name":"ProdTest","description":"В проде"}'
   ```

2. **Получение по ID**

   ```bash
   curl $API_URL/items/<ID>
   ```

3. **Сканирование**

   ```bash
   curl $API_URL/items/?limit=100
   ```

## Полезные ссылки

* [FastAPI](https://fastapi.tiangolo.com/)
* [LocalStack](https://github.com/localstack/localstack)
* [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
* [Boto3 Documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/index.html)
* [Pydantic](https://docs.pydantic.dev/)

