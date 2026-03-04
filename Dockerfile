FROM python:3.10-alpine

# 1. Системные зависимости + Сертификаты
RUN apk add --no-cache \
    libpcap-dev \
    gcc \
    musl-dev \
    linux-headers \
    curl \
    unzip \
    ca-certificates

# 2. Скачивание Xray с дополнительными флагами стабильности
# -f (fail silently), -s (silent), -S (show error), -L (follow redirects)
RUN curl -f -s -S -L -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7.zip" && \
    unzip -o /tmp/xray.zip -d /tmp/xray_files && \
    mv /tmp/xray_files/xray /usr/bin/xray && \
    chmod +x /usr/bin/xray && \
    rm -rf /tmp/xray.zip /tmp/xray_files

# 3. Библиотеки Python
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# 4. Запуск в JSON-формате
# Важно: убедись, что файл /etc/xray/config.json существует или закомментируй флаг -config
CMD ["sh", "-c", "xray -version && python main.py"]
