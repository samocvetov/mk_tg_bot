FROM python:3.10-alpine

# 1. Системные зависимости + сертификаты
RUN apk add --no-cache \
    libpcap-dev \
    gcc \
    musl-dev \
    linux-headers \
    wget \
    unzip \
    ca-certificates

# 2. Скачивание Xray v1.8.4 (Прямая ссылка на конкретную версию)
# Это исключает ошибку редиректа GitHub
RUN wget https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-arm32-v7.zip -O /tmp/xray.zip && \
    mkdir -p /tmp/xray_temp && \
    unzip /tmp/xray.zip -d /tmp/xray_temp && \
    mv /tmp/xray_temp/xray /usr/bin/xray && \
    chmod +x /usr/bin/xray && \
    rm -rf /tmp/xray.zip /tmp/xray_temp

# 3. Установка библиотек Python
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# 4. JSON-формат для CMD
# Проверяем xray при старте
CMD ["sh", "-c", "xray -version && python main.py"]
