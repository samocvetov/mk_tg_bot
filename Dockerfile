FROM python:3.10-alpine

# 1. Только нужные системные библиотеки для работы сети
RUN apk add --no-cache libpcap-dev gcc musl-dev linux-headers

# 2. Копируем бинарник xray, который скачал GitHub Actions
COPY xray /usr/bin/xray

# 3. Установка библиотек Python
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# 4. Запуск
CMD ["sh", "-c", "xray -version && python main.py"]
