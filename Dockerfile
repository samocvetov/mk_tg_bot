FROM python:3.10-alpine

# 1. Системные зависимости + сертификаты безопасности
RUN apk add --no-cache \
    libpcap-dev \
    gcc \
    musl-dev \
    linux-headers \
    wget \
    unzip \
    ca-certificates

# 2. Скачивание Xray через wget (более надежен в CI/CD)
# Скачиваем во временную папку, распаковываем и переносим только бинарник
RUN wget --no-check-certificate https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7.zip -O /tmp/xray.zip && \
    mkdir -p /tmp/xray_temp && \
    unzip /tmp/xray.zip -d /tmp/xray_temp && \
    mv /tmp/xray_temp/xray /usr/bin/xray && \
    chmod +x /usr/bin/xray && \
    rm -rf /tmp/xray.zip /tmp/xray_temp

# 3. Установка библиотек Python
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# 4. JSON-формат для CMD (убирает Warning)
# Проверяем версию xray при старте, чтобы убедиться, что он живой
CMD ["sh", "-c", "xray -version && python main.py"]
