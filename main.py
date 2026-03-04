import os
import sqlite3
import threading
import logging
from scapy.all import *
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

# Настройка логирования для отладки в MikroTik
logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.INFO)

# Параметры из окружения MikroTik
TOKEN = os.getenv("TG_TOKEN")
ADMIN_ID = os.getenv("ADMIN_ID")
DB_PATH = "/disk1/wifi_scanner.db"

# --- ИНИЦИАЛИЗАЦИЯ БАЗЫ ДАННЫХ ---
def init_db():
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute('''CREATE TABLE IF NOT EXISTS scans 
                   (mac TEXT, rssi INTEGER, timestamp DATETIME DEFAULT CURRENT_TIMESTAMP)''')
    # Индекс для быстрого поиска
    cursor.execute('''CREATE INDEX IF NOT EXISTS idx_mac_time ON scans (mac, timestamp)''')
    conn.commit()
    conn.close()

# --- ОБРАБОТЧИК ПАКЕТОВ (TZSP) ---
def handle_tzsp(pkt):
    # Пакет от MikroTik приходит как UDP, внутри которого инкапсулирован Wi-Fi фрейм
    if pkt.haslayer(Dot11ProbeReq):
        try:
            mac = pkt[Dot11].addr2.upper()
            rssi = pkt[RadioTap].dBm_AntSignal if pkt.haslayer(RadioTap) else 0
            
            conn = sqlite3.connect(DB_PATH)
            cursor = conn.cursor()
            cursor.execute("INSERT INTO scans (mac, rssi) VALUES (?, ?)", (mac, rssi))
            conn.commit()
            
            # Логика детектора: проверяем, был ли этот MAC за последние 2 часа более 3 раз
            cursor.execute("""SELECT COUNT(*) FROM scans 
                              WHERE mac=? AND timestamp > datetime('now', '-2 hours')""", (mac,))
            count = cursor.fetchone()[0]
            
            if count == 3:
                # Здесь можно добавить уведомление через бота, если передать объект app
                logging.info(f"ALERT: Device {mac} seen {count} times lately!")
            
            conn.close()
        except Exception as e:
            logging.error(f"Error processing packet: {e}")

# --- КОМАНДЫ ТЕЛЕГРАМ-БОТА ---
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if str(update.effective_user.id) != ADMIN_ID: return
    await update.message.reply_text("🕵️ Робот-охранник MikroTik в сети. Используй /wifistats или /wifitop")

async def stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Текстовая тепловая карта вместо графиков"""
    if str(update.effective_user.id) != ADMIN_ID: return
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    # Группируем активность по часам за последние 24 часа
    cursor.execute("""SELECT strftime('%H:00', timestamp) as hr, COUNT(*) 
                      FROM scans 
                      WHERE timestamp > datetime('now', '-1 day')
                      GROUP BY hr ORDER BY hr ASC""")
    data = cursor.fetchall()
    conn.close()
    
    if not data:
        await update.message.reply_text("Данных пока нет. Ждем прохожих...")
        return

    report = "📊 **Активность у окна (24ч):**\n\n"
    for hr, count in data:
        # Рисуем простую полоску из символов для визуализации
        bar = "🟦" * min(int(count/5) + 1, 10) 
        report += f"`{hr}` {bar} ({count})\n"
    
    await update.message.reply_text(report, parse_mode='Markdown')

async def top_guests(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Список самых частых MAC-адресов"""
    if str(update.effective_user.id) != ADMIN_ID: return
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("""SELECT mac, COUNT(*) as hits 
                      FROM scans 
                      GROUP BY mac 
                      ORDER BY hits DESC LIMIT 10""")
    rows = cursor.fetchall()
    conn.close()
    
    msg = "🔝 **Топ-10 частых гостей:**\n\n"
    for i, (mac, hits) in enumerate(rows, 1):
        msg += f"{i}. `{mac}` — {hits} раз\n"
    
    await update.message.reply_text(msg, parse_mode='Markdown')

# --- ЗАПУСК СИСТЕМЫ ---
if __name__ == '__main__':
    init_db()
    
    # Запускаем сниффер TZSP в фоновом потоке
    # MikroTik шлет данные на порт 37008
    sniffer_thread = threading.Thread(
        target=lambda: sniff(iface="eth0", prn=handle_tzsp, filter="udp port 37008", store=0),
        daemon=True
    )
    sniffer_thread.start()
    
    # Запускаем Telegram-бота
    application = Application.builder().token(TOKEN).build()
    
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("wifistats", stats))
    application.add_handler(CommandHandler("wifitop", top_guests))
    
    application.run_polling()
