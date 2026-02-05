#!/bin/bash

# Настройки (измени под себя)
#PROXY_USER="admin"
#PROXY_PASS="passadmin"
#PROXY_PORT="8080"

echo "\e[38;2;0;255;255m--- 1. Установка Cloudflare WARP ---\e[0m"
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt update && sudo apt install cloudflare-warp -y

echo "\e[38;2;0;255;255m--- 2. Настройка WARP в режиме Proxy ---\e[0m"
warp-cli registration new
warp-cli mode proxy
warp-cli proxy port 4000
warp-cli connect

echo "\e[38;2;0;255;255m--- 3. Установка GOST (входной мост) ---\e[0m"
GOST_VERSION="3.0.0-rc10"
wget https://github.com/go-gost/gost/releases/download/v${GOST_VERSION}/gost_${GOST_VERSION}_linux_amd64.tar.gz
tar -xvzf gost_${GOST_VERSION}_linux_amd64.tar.gz
sudo mv gost /usr/bin/
rm gost_${GOST_VERSION}_linux_amd64.tar.gz README* LICENSE*

echo "\e[38;2;0;255;255m--- 4. Создание службы для автозапуска GOST ---\e[0m"
sudo tee /etc/systemd/system/gost.service > /dev/null <<EOF
[Unit]
Description=Gost Proxy Bridge
After=network.target warp-svc.service

[Service]
Type=simple
ExecStart=/usr/bin/gost -L PROXY_USER:PROXY_PASS@:PROXY_PORT -F socks5://127.0.0.1:4000
Restart=always

[Install]
WantedBy=multi-user.target
EOF
echo "\e[38;2;0;255;255m--- Укажите логин для внешнего прокси: ---\e[0m"
read login
sed -i 's/PROXY_USER/'$login'/g' /etc/systemd/system/gost.service
echo "\e[38;2;0;255;255m--- Укажите пароль для внешнего прокси: ---\e[0m"
read password
sed -i 's/PROXY_PASS/'$password'/g' /etc/systemd/system/gost.service
echo "\e[38;2;0;255;255m--- Укажите внешний порт прокси: ---\e[0m"
read port
sed -i 's/PROXY_PORT/'$port'/g' /etc/systemd/system/gost.service /etc/systemd/system/gost.service
sudo systemctl daemon-reload
sudo systemctl enable --now gost

echo "		\e[38;2;0;255;255m--- Успех! ---\e[0m"
sleep 5
clear
ss -tlnp | grep 4000
curl -x socks5h://127.0.0.1:4000 https://www.cloudflare.com/cdn-cgi/trace

    echo "\e[38;2;0;255;255m"
    echo "-----------------------------------------------------------------"
    echo "			ГОТОВО!"
    echo "	Ваш внешний прокси: SOCKS5 или HTTP"
    echo "	Адрес: $(curl -s -4 https://ifconfig.me):${port}"
    echo "	Логин: ${login}"
    echo "	Пароль: ${password}"
    echo "	Ваш внутренний прокси SOCKS (без логина и пароля)"
    echo "	127.0.0.1:4000"
    echo "-----------------------------------------------------------------"
    echo "\e[0m"
#    echo "\e[38;2;0;255;255m-----------------------------------------------------------------\e[0m"
#    echo "	Для смены логина и пароля отредактируйте"
#    echo "	/etc/systemd/system/gost.service и перезапустите службы"
#    echo "	\e[91msystemctl daemon-reload\e[0m"
#    echo "	\e[91msystemctl restart gost.service\e[0m"
#    echo "\e[38;2;0;255;255m-----------------------------------------------------------------\e[0m"

