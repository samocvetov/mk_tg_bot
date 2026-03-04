import os
import sqlite3
import threading
from scapy.all import *
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

# --- НАСТРОЙКИ ---
TOKEN = os.getenv("TG_TOKEN")
ADMIN_ID = os.getenv("ADMIN_ID")
DB_PATH = "/disk1/wifi_data.db" # База на внешней флешке

# --- БАЗА ДАННЫХ ---
def init_db():
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    # Таблица для хранения уникальных MAC-адресов и времени их появления
    cur.execute('''CREATE TABLE IF NOT EXISTS devices 
                   (mac TEXT PRIMARY KEY, 
                    first_seen DATETIME, 
                    last_seen DATETIME, 
                    hits INTEGER DEFAULT 1)''')
    conn.commit()
    conn.close()

# --- ЛОГИКА СКАНИРОВАНИЯ (TZSP) ---
def packet_handler(pkt):
    # Проверяем, является ли пакет запросом на поиск сети (Probe Request)
    if pkt.haslayer(Dot11ProbeReq):
        mac = pkt[Dot11].addr2.upper()
        
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        
        # SQL-магия: если MAC новый - вставляем, если старый - обновляем время и счетчик
        cur.execute('''INSERT INTO devices (mac, first_seen, last_seen, hits) 
                       VALUES (?, datetime('now'), datetime('now'), 1)
                       ON CONFLICT(mac) DO UPDATE SET 
                       last_seen=datetime('now'), 
                       hits=hits+1''', (mac,))
        
        # Пример детектора "подозрительного соседа"
        cur.execute("SELECT hits FROM devices WHERE mac=?", (mac,))
        hits = cur.fetchone()[0]
        if hits == 10: # Оповестить только на 10-е появление
            print(f"DEBUG: Подозрительная активность: {mac}")
            
        conn.commit()
        conn.close()

# Запуск сниффера в отдельном потоке, чтобы не блокировать бота
def start_sniffer():
    # Слушаем только UDP порт 37008 (стандарт TZSP)
    sniff(iface="eth0", prn=packet_handler, filter="udp port 37008", store=0)

# --- КОМАНДЫ TELEGRAM ---
async def wifitop(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if str(update.effective_user.id) != ADMIN_ID: return
    
    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()
    cur.execute("SELECT mac, hits FROM devices ORDER BY hits DESC LIMIT 10")
    rows = cur.fetchall()
    
    msg = "📊 **Топ частых гостей:**\n\n"
    for r in rows:
        msg += f"`{r[0]}` — {r[1]} раз\n"
    
    await update.message.reply_text(msg, parse_mode='Markdown')

# --- ЗАПУСК ---
if __name__ == '__main__':
    init_db()
    
    # Стартуем радио-ухо
    threading.Thread(target=start_sniffer, daemon=True).start()
    
    # Стартуем бота
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("wifitop", wifitop))
    print("Система запущена...")
    app.run_polling()
