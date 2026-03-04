# 1. Настройка "Прозрачной точки"
/interface bridge add name=bridge-clean
/interface bridge port add bridge=bridge-clean interface=ether1
/interface bridge port add bridge=bridge-clean interface=wlan1
/interface bridge port add bridge=bridge-clean interface=wlan2
/ip dhcp-client add interface=bridge-clean disabled=no

# 2. Виртуальная сеть для контейнера
/interface veth add name=veth1 address=172.17.0.2/24 gateway=172.17.0.1
/interface bridge add name=bridge-containers
/interface bridge port add bridge=bridge-containers interface=veth1
/ip address add address=172.17.0.1/24 interface=bridge-containers
/ip firewall nat add chain=srcnat src-address=172.17.0.0/24 action=masquerade

# 3. Настройка Радио-перехвата (Monitor Mode)
/interface wireless set [find default-name=wlan1] mode=station-bridge disabled=no
/interface wireless sniffer set streaming-enabled=yes streaming-server=172.17.0.2

# 4. Установка контейнера из твоего Docker Hub
/container config set ram-high=100M tmpdir=disk1/tmp
/container envs add name=bot_env key=TG_TOKEN value="ТВОЙ_ТОКЕН_БОТА"
/container envs add name=bot_env key=ADMIN_ID value="ТВОЙ_ID"

/container add remote-image=твой_логин_dockerhub/mk_tg_bot:latest \
    interface=veth1 root-dir=disk1/bot envlist=bot_env logging=yes

# Ждем 10 секунд и запускаем
:delay 10s
/container start [find]
