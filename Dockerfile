FROM python:3.10-alpine

# Устанавливаем системные зависимости, необходимые для захвата пакетов (libpcap)
RUN apk add --no-cache \
    libpcap-dev \
    gcc \
    musl-dev \
    linux-headers \
    curl \
    unzip

# Скачиваем Xray (бинарник для ARM v7)
RUN curl -L -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm32-v7.zip \
    && unzip /tmp/xray.zip -d /usr/bin/ \
    && chmod +x /usr/bin/xray \
    && rm /tmp/xray.zip

# Устанавливаем только необходимые легкие библиотеки
# Убираем pandas и matplotlib, чтобы контейнер влез в память MikroTik
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .
# Если у тебя есть конфиг xray, раскомментируй строку ниже
# COPY xray_config.json /etc/xray/config.json

# Запуск
CMD xray -config /etc/xray/config.json & python main.py
