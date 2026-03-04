FROM python:3.10-alpine

# 1. Устанавливаем системные зависимости + сертификаты
RUN apk add --no-cache \
    libpcap-dev \
    gcc \
    musl-dev \
    linux-headers \
    curl \
    unzip \
    ca-certificates

# 2. Скачиваем Xray (используем -k если есть проблемы с SSL, но лучше обновить сертификаты)
RUN curl -L -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7.zip" \
    && unzip /tmp/xray.zip -d /usr/bin/ \
    && chmod +x /usr/bin/xray \
    && rm /tmp/xray.zip

# 3. Устанавливаем библиотеки Python
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# 4. Исправляем CMD на JSON-формат (убирает Warning)
# Используем sh -c чтобы запустить два процесса параллельно
CMD ["sh", "-c", "xray -config /etc/xray/config.json & python main.py"]
