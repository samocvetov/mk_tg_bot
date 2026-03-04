FROM python:3.10-alpine
# 1. Системные зависимости
RUN apk add --no-cache libpcap-dev gcc musl-dev linux-headers
# 2. Копируем бинарник (он теперь точно будет в корне рядом с Dockerfile)
COPY xray /usr/bin/xray
RUN chmod +x /usr/bin/xray
# 3. Установка библиотек Python
RUN pip install --no-cache-dir python-telegram-bot scapy
WORKDIR /app
COPY main.py .
CMD ["sh", "-c", "xray -version && python main.py"]
