# --- 1. Bridge & IP (Прозрачный режим) ---
/interface bridge add name=BR-LAN
/interface bridge port add bridge=BR-LAN interface=ether1
/interface bridge port add bridge=BR-LAN interface=all-wireless
/ip dhcp-client add interface=BR-LAN disabled=no

# --- 2. Контейнерная среда ---
/interface veth add name=veth-bot address=172.17.0.2/24 gateway=172.17.0.1
/interface bridge add name=BR-CONT
/interface bridge port add bridge=BR-CONT interface=veth-bot
/ip address add address=172.17.0.1/24 interface=BR-CONT
/ip firewall nat add chain=srcnat src-address=172.17.0.0/24 action=masquerade

# --- 3. Радио-сканер (Слушаем эфир) ---
/interface wireless set [find default-name=wlan1] mode=station-bridge disabled=no
/interface wireless sniffer set streaming-enabled=yes streaming-server=172.17.0.2

# --- 4. Установка контейнера (Замени на свой Docker Hub image) ---
/container config set ram-high=95M tmpdir=disk1/tmp
/container envs add name=bot_envs key=TG_TOKEN value="твой_токен"
/container envs add name=bot_envs key=ADMIN_ID value="твой_айди"

/container add remote-image=samocvetov/mk_tg_bot:latest interface=veth-bot \
    root-dir=disk1/bot envlist=bot_envs logging=yes
