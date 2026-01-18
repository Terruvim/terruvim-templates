# Auditstage Backend CI/CD Configuration

## 📁 Структура файлов

```
assets/
├── basic-spring-boot/
│   └── Dockerfile                    # Dockerfile для Spring Boot приложения
└── buildspecs/
    └── buildspec-backend-be.yml      # CodeBuild buildspec для backend
```

## 🐳 Dockerfile

### Особенности:
- **Многостадийная сборка** для оптимизации размера образа
- **Amazon Corretto 17** как базовый образ
- **Непривилегированный пользователь** для безопасности
- **Health check** для мониторинга состояния
- **Оптимизированные JVM параметры** для контейнерной среды

### Порты:
- **8080** - основной порт приложения
- **Health check** на `/actuator/health`

## ⚙️ BuildSpec

### Фазы сборки:

1. **Install**
   - Java 17 (Amazon Corretto)
   - Необходимые инструменты (jq)

2. **Pre-build**
   - Аутентификация в ECR
   - Проверка environment variables
   - Версии Java и Gradle

3. **Build**
   - Запуск тестов: `./gradlew clean test`
   - Сборка JAR: `./gradlew build -x test`
   - Сборка Docker образа
   - Тегирование образа

4. **Post-build**
   - Push образа в ECR
   - Генерация `imagedefinitions.json` для ECS

### Environment Variables:

| Переменная | Описание |
|------------|----------|
| `ECR_REPO_NAME` | Имя ECR репозитория |
| `ECR_REPO_URI` | URI ECR репозитория |
| `CONTAINER_NAME` | Имя контейнера для ECS |
| `IMAGE_TAG` | Тег Docker образа |
| `GITHUB_USERNAME` | Username для GitHub Packages |
| `GITHUB_TOKEN` | Token для доступа к GitHub Packages |

## 🔧 Spring Boot Environment Variables

### Production (infrastructure.prod.json):
- `SPRING_PROFILES_ACTIVE=prod`
- Database connection через AWS Secrets Manager
- Отключенные Swagger/API docs
- Media storage: `auditstage-media-prod`

### Development (infrastructure.dev.json):
- `SPRING_PROFILES_ACTIVE=dev`
- Включенные Swagger/API docs
- Media storage: `auditstage-media-dev`
- Debug logging для Hibernate

## 🔐 Secrets

Необходимые secrets в `auditstage/global-secrets-base`:
- `GITHUB_USERNAME` - для доступа к GitHub Packages
- `GITHUB_TOKEN` - для доступа к GitHub Packages
- `CHATBOT_SEND_MAIL_TOKEN` - для чатбота
- `AWS_ACCESS_KEY_DEV` - для dev среды
- `AWS_SECRET_KEY_DEV` - для dev среды

## 📦 Зависимости

### GitHub Packages:
- `com.auditstage.common:commons:3.0.3-SNAPSHOT`
- Требует аутентификацию через GITHUB_USERNAME/GITHUB_TOKEN

### Основные зависимости:
- Spring Boot 3.0.5
- PostgreSQL 42.6.0
- Liquibase 4.23.1
- AWS SDK для Secrets Manager

## 🚀 Деплойment

1. **CodeBuild** собирает JAR и Docker образ
2. **ECR** хранит Docker образы
3. **ECS** запускает контейнеры на порту 8080
4. **ALB** роутит трафик на `/be/*` path

## 🔍 Мониторинг

- Health check: `http://localhost:8080/actuator/health`
- Metrics: `http://localhost:8080/actuator/metrics`
- CloudWatch Logs: `/ecs/be`
