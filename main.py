import os
import sqlite3
import threading
from scapy.all import *
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

# Конфигурация
TOKEN = os.getenv("TG_TOKEN")
ADMIN_ID = os.getenv("ADMIN_ID")
DB_PATH = "/disk1/wifi_scanner.db"

def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.execute("CREATE TABLE IF NOT EXISTS scans (mac TEXT, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)")
    conn.execute("CREATE INDEX IF NOT EXISTS idx_mac ON scans(mac)")
    conn.commit()
    conn.close()

def handle_tzsp(pkt):
    if pkt.haslayer(Dot11ProbeReq):
        try:
            mac = pkt[Dot11].addr2.upper()
            conn = sqlite3.connect(DB_PATH)
            conn.execute("INSERT INTO scans (mac) VALUES (?)", (mac,))
            conn.commit()
            conn.close()
        except:
            pass

async def stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if str(update.effective_user.id) != ADMIN_ID: return
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT strftime('%H:00', timestamp) as hr, COUNT(*) FROM scans WHERE timestamp > datetime('now', '-1 day') GROUP BY hr")
    data = cursor.fetchall()
    conn.close()
    
    report = "📊 *Активность за 24 часа:*\n"
    for hr, count in data:
        bar = "🟦" * min(int(count/10)+1, 10)
        report += f"`{hr}` {bar} ({count})\n"
    await update.message.reply_text(report or "Нет данных", parse_mode='Markdown')

if __name__ == '__main__':
    init_db()
    # Сниффер TZSP на порту 37008
    threading.Thread(target=lambda: sniff(iface="eth0", prn=handle_tzsp, filter="udp port 37008", store=0), daemon=True).start()
    
    app = Application.builder().token(TOKEN).build()
    app.add_handler(CommandHandler("wifistats", stats))
    print("Бот запущен...")
    app.run_polling()
