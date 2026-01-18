# Dockerfile для Auditstage Backend (Spring Boot)
# Многостадийная сборка для оптимизации размера образа

# Стадия 1: Сборка приложения
FROM amazoncorretto:17-alpine AS builder

WORKDIR /app

# Копируем gradle wrapper и конфигурационные файлы
COPY gradle/ gradle/
COPY gradlew gradlew.bat build.gradle settings.gradle gradle.properties ./

# Делаем gradlew исполняемым
RUN chmod +x gradlew

# Загружаем зависимости (для кэширования слоя)
RUN ./gradlew dependencies --no-daemon

# Копируем исходный код
COPY src/ src/

# Собираем приложение
RUN ./gradlew build -x test --no-daemon

# Стадия 2: Рабочий образ
FROM amazoncorretto:17-alpine

# Установка необходимых пакетов для production
RUN apk add --no-cache \
    curl \
    tzdata \
    ca-certificates

# Создание пользователя для безопасности
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001 -G appuser

# Создание рабочей директории
WORKDIR /app

# Копирование JAR файла из builder стадии
COPY --from=builder /app/build/libs/auditstage-backend-*.jar app.jar

# Установка владельца файлов
RUN chown -R appuser:appuser /app

# Переключение на непривилегированного пользователя
USER appuser

# Настройка переменных окружения
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC -XX:G1HeapRegionSize=16m -XX:+UseContainerSupport"
ENV SPRING_PROFILES_ACTIVE="prod"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/actuator/health || exit 1

# Открываем порт
EXPOSE 8080

# Запуск приложения
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
