# --- 1. Сетевая настройка (Bridge Mode) ---
/interface bridge add name=bridge-lan
/interface bridge port add bridge=bridge-lan interface=ether1
/interface bridge port add bridge=bridge-lan interface=wlan1
/interface bridge port add bridge=bridge-lan interface=wlan2

/ip dhcp-client add interface=bridge-lan disabled=no

# --- 2. Настройка виртуальной сети для контейнеров ---
/interface veth add name=veth1 address=172.17.0.2/24 gateway=172.17.0.1
/interface bridge add name=bridge-containers
/interface bridge port add bridge=bridge-containers interface=veth1
/ip address add address=172.17.0.1/24 interface=bridge-containers

# NAT для контейнера, чтобы он видел интернет через основной шлюз
/ip firewall nat add chain=srcnat src-address=172.17.0.0/24 action=masquerade

# --- 3. Радио-сканер (TZSP Stream) ---
# Настраиваем wlan1 на прослушку (Monitor Mode) и стриминг в контейнер
/interface wireless set [ find default-name=wlan1 ] mode=station-dump
/interface wireless sniffer set streaming-enabled=yes streaming-server=172.17.0.2

# --- 4. Подготовка диска ---
/container config set ram-high=90M tmpdir=disk1/tmp

# --- 5. Загрузка и запуск (пример команды) ---
# /container add remote-image=python:3.10-alpine interface=veth1 root-dir=disk1/bot \
# envlist=bot_envs logging=yes
