FROM python:3.10-alpine

# Устанавливаем системные зависимости для работы с сетью
RUN apk add --no-cache libpcap-dev gcc musl-dev linux-headers

# Копируем бинарник xray, подготовленный на предыдущем шаге
COPY xray /usr/bin/xray

# Устанавливаем библиотеки для бота и сниффера
RUN pip install --no-cache-dir python-telegram-bot scapy

WORKDIR /app
COPY main.py .

# Запуск xray в фоне и затем нашего бота
CMD ["sh", "-c", "xray -version && python main.py"]
