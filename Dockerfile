FROM python:3.10-alpine

# 1. Устанавливаем зависимости и сертификаты для работы HTTPS
RUN apk add --no-cache \
    libpcap-dev \
    gcc \
    musl-dev \
    linux-headers \
    curl \
    unzip \
    ca-certificates

# 2. Скачиваем Xray. 
# Используем флаги: -f (ошибка при сбое), -sS (скрыть прогресс, но показать ошибку), -L (переходить по редиректам)
RUN curl -fsSL -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7.zip" && \
    mkdir -p /tmp/xray_dist && \
    unzip -q /tmp/xray.zip -d /tmp/xray_dist && \
    mv /tmp/xray_dist/xray /usr/bin/xray && \
    chmod +x /usr/bin/xray && \
    rm -rf /tmp/xray.zip /tmp/xray_dist

# 3. Устанавливаем библиотеки Python
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# 4. JSON-формат для CMD (убирает Warning и правильно прокидывает сигналы завершения)
# Запускаем xray в фоне, затем основной скрипт
CMD ["sh", "-c", "xray -version && python main.py"]
