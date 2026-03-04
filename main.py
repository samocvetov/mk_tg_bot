import os
import sqlite3
from scapy.all import *
from telegram import Update
from telegram.ext import Application, CommandHandler
import matplotlib.pyplot as plt

# Настройки
DB_PATH = "/disk1/wifi_scanner.db"
ADMIN_ID = os.getenv("ADMIN_ID")

# Инициализация БД
conn = sqlite3.connect(DB_PATH, check_same_thread=False)
cursor = conn.cursor()
cursor.execute('''CREATE TABLE IF NOT EXISTS scans 
               (mac TEXT, rssi INTEGER, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')
conn.commit()

def handle_tzsp(pkt):
    # MikroTik шлет Probe Request внутри UDP/TZSP
    if pkt.haslayer(Dot11ProbeReq):
        mac = pkt[Dot11].addr2
        rssi = pkt[RadioTap].dBm_AntSignal if pkt.haslayer(RadioTap) else 0
        
        cursor.execute("INSERT INTO scans (mac, rssi) VALUES (?, ?)", (mac, rssi))
        conn.commit()
        
        # Логика алертов: если MAC всплывал > 3 раз за 2 часа
        cursor.execute("SELECT COUNT(*) FROM scans WHERE mac=? AND timestamp > datetime('now', '-2 hours')", (mac,))
        if cursor.fetchone()[0] == 3:
             # Тут отправка сообщения ботом (код сокращен для краткости)
             print(f"Alert: {mac} is lurking!")

async def stats(update: Update, context):
    # Генерация графика Heatmap
    cursor.execute("SELECT strftime('%H', timestamp) as hr, count(*) FROM scans GROUP BY hr")
    data = cursor.fetchall()
    hrs, counts = zip(*data)
    
    plt.bar(hrs, counts)
    plt.title("WiFi Activity Heatmap")
    plt.savefig("/tmp/stats.png")
    await update.message.reply_photo(photo=open("/tmp/stats.png", "rb"))

# Запуск сниффера в отдельном потоке
import threading
threading.Thread(target=lambda: sniff(iface="eth0", prn=handle_tzsp, filter="udp port 37008"), daemon=True).start()

# Запуск Telegram Bot
app = Application.builder().token(os.getenv("TG_TOKEN")).build()
app.add_handler(CommandHandler("wifistats", stats))
app.run_polling()
