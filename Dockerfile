FROM python:3.10-alpine

# Устанавливаем зависимости для Scapy, SQLite и скачиваем Xray
RUN apk add --no-cache libpcap-dev gcc musl-dev linux-headers curl executable-stack \
    && curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7.zip \
    && unzip /tmp/xray.zip -d /usr/bin/ && rm /tmp/xray.zip \
    && pip install --no-cache-dir python-telegram-bot scapy matplotlib pandas

WORKDIR /app
COPY main.py .
COPY xray_config.json /etc/xray/config.json

# Запуск: Сначала Xray в фоне, потом наш бот-сканер
CMD xray -config /etc/xray/config.json & python main.py
