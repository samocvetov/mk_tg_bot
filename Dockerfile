FROM python:3.10-alpine

# 1. Системные зависимости
RUN apk add --no-cache libpcap-dev gcc musl-dev linux-headers unzip ca-certificates

# 2. Скачивание Xray через Python (более надежный метод в CI/CD)
RUN python3 -c 'import urllib.request; urllib.request.urlretrieve("https://github.com/XTLS/Xray-core/releases/download/v1.8.4/Xray-linux-arm32-v7.zip", "/tmp/xray.zip")' && \
    mkdir -p /tmp/xray_temp && \
    unzip /tmp/xray.zip -d /tmp/xray_temp && \
    mv /tmp/xray_temp/xray /usr/bin/xray && \
    chmod +x /usr/bin/xray && \
    rm -rf /tmp/xray.zip /tmp/xray_temp

# 3. Установка библиотек бота
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# 4. Запуск
CMD ["sh", "-c", "xray -version && python main.py"]
