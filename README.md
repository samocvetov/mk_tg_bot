/tool fetch url="https://raw.githubusercontent.com/samocvetov/mk_tg_bot/main/setup.rsc" dst-path=setup.rsc;
/import setup.rsc;

/container envs add name=bot_envs key=TG_TOKEN value="ВАШ_ТОКЕН"
/container envs add name=bot_envs key=ADMIN_ID value="ВАШ_ID"
