FROM python:3.10-alpine

# Системные зависимости для сборки Scapy
RUN apk add --no-cache libpcap-dev gcc musl-dev linux-headers

# Копируем бинарник xray из корня сборки
COPY xray /usr/bin/xray

# Устанавливаем библиотеки Python (без тяжелых pandas/matplotlib)
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# Запуск xray в фоне и переход к боту
CMD ["sh", "-c", "xray -version && python main.py"]
