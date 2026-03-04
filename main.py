import os, sqlite3, threading
from scapy.all import *
from telegram.ext import Application, CommandHandler

# Настройки из переменных окружения MikroTik
TOKEN = os.getenv("TG_TOKEN")
ADMIN_ID = os.getenv("ADMIN_ID")
DB_PATH = "/disk1/wifi_data.db"

# Инициализация БД на флешке
db = sqlite3.connect(DB_PATH, check_same_thread=False)
db.execute("CREATE TABLE IF NOT EXISTS devices (mac TEXT, last_seen DATETIME, count INTEGER)")

def packet_callback(pkt):
    if pkt.haslayer(Dot11ProbeReq):
        mac = pkt.addr2
        db.execute("INSERT INTO devices (mac, last_seen, count) VALUES (?, datetime('now'), 1) "
                   "ON CONFLICT(mac) DO UPDATE SET last_seen=datetime('now'), count=count+1", (mac,))
        db.commit()

async def start_cmd(update, context):
    await update.message.reply_text("Система мониторинга MikroTik запущена!")

async def stats_cmd(update, context):
    cursor = db.execute("SELECT mac, count FROM devices ORDER BY count DESC LIMIT 5")
    res = "\n".join([f"{row[0]}: {row[1]} раз" for row in cursor.fetchall()])
    await update.message.reply_text(f"Топ гостей под окном:\n{res}")

# Запуск сниффера TZSP в фоне
threading.Thread(target=lambda: sniff(iface="eth0", prn=packet_callback, filter="udp port 37008"), daemon=True).start()

# Запуск бота
app = Application.builder().token(TOKEN).build()
app.add_handler(CommandHandler("start", start_cmd))
app.add_handler(CommandHandler("wifitop", stats_cmd))
app.run_polling()
