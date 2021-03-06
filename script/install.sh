#!/bin/bash

installNodeAndYarn () {
    echo "Installing nodejs and yarn..."
    sudo curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
    sudo apt-get install -y nodejs npm
    sudo curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    sudo echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update -y
    sudo apt-get install -y yarn
    sudo npm install -g pm2
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo chown -R explorer:explorer /home/bxg/.config
    clear
}

installNginx () {
    echo "Installing nginx..."
    sudo apt-get install -y nginx
    sudo rm -f /etc/nginx/sites-available/default
    sudo cat > /etc/nginx/sites-available/default << EOL
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;
    #server_name explorer.blockchaingold.games;
    server_name _;

    gzip on;
    gzip_static on;
    gzip_disable "msie6";

    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_buffers 16 8k;
    gzip_http_version 1.1;
    gzip_min_length 256;
    gzip_types text/plain text/css application/json application/javascript application/x-javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL
    sudo systemctl start nginx
    sudo systemctl enable nginx
    clear
}

installMongo () {
    echo "Installing mongodb..."
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5
    sudo echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list
    sudo apt-get update -y
    sudo apt-get install -y --allow-unauthenticated mongodb-org
    sudo chown -R mongodb:mongodb /data/db
    sudo systemctl start mongod
    sudo systemctl enable mongod
    mongo blockexplorer --eval "db.createUser( { user: \"$rpcuser\", pwd: \"$rpcpassword\", roles: [ \"readWrite\" ] } )"
    clear
}

installWallet () {
    echo "Installing Blockchain Gold..."
    mkdir -p /tmp/blockchaingold
    cd /tmp/blockchaingold
    curl -Lo blockchaingold.tar.gz $bxglink
    tar -xzf blockchaingold.tar.gz
    sudo mv ./bin/* /usr/local/bin
    cd
    rm -rf /tmp/blockchaingold
    mkdir -p /home/bxg/.blockchaingold
    cat > /home/bxg/.blockchaingold/blockchaingold.conf << EOL
rpcport=13512
rpcuser=$rpcuser
rpcpassword=$rpcpassword
daemon=1
txindex=1
EOL
    sudo cat > /etc/systemd/system/blockchaingoldd.service << EOL
[Unit]
Description=blockchaingoldd
After=network.target
[Service]
Type=forking
User=explorer
WorkingDirectory=/home/bxg
ExecStart=/home/bxg/bin/blockchaingoldd -datadir=/home/bxg/.blockchaingold
ExecStop=/home/bxg/bin/blockchaingold-cli -datadir=/home/bxg/.blockchaingold stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOL
    sudo systemctl start blockchaingoldd
    sudo systemctl enable blockchaingoldd
    echo "Sleeping for 1 hour while node syncs blockchain..."
    sleep 1h
    clear
}

installBlockExplorer () {
    echo "Installing Block Explorer..."
    git clone https://github.com/blockchain-gold/bxg-explorer.git /home/bxg/blockexplorer
    cd /home/bxg/blockexplorer
    yarn install
    cat > /home/bxg/blockexplorer/config.js << EOL
const config = {
  api: {
    host: 'https://explorer.blockchaingold.games',
    port: '3000',
    prefix: '/api',
    timeout: '180s'
  },
  coinMarketCap: {
    api: 'http://api.coinmarketcap.com/v1/ticker/',
    ticker: 'bxg'
  },
  db: {
    host: '127.0.0.1',
    port: '27017',
    name: 'blockexplorer',
    user: '$rpcuser',
    pass: '$rpcpassword'
  },
  freegeoip: {
    api: 'https://extreme-ip-lookup.com/json/'
  },
  rpc: {
    host: '127.0.0.1',
    port: '13512',
    user: '$rpcuser',
    pass: '$rpcpassword',
    timeout: 12000, // 12 seconds
  }
};

module.exports = config;
EOL
    nodejs ./cron/block.js
    nodejs ./cron/coin.js
    nodejs ./cron/masternode.js
    nodejs ./cron/peer.js
    nodejs ./cron/rich.js
    clear
    cat > mycron << EOL
*/1 * * * * cd /home/bxg/blockexplorer && ./script/cron_block.sh >> ./tmp/block.log 2>&1
*/1 * * * * cd /home/bxg/blockexplorer && /usr/bin/nodejs ./cron/masternode.js >> ./tmp/masternode.log 2>&1
*/1 * * * * cd /home/bxg/blockexplorer && /usr/bin/nodejs ./cron/peer.js >> ./tmp/peer.log 2>&1
*/1 * * * * cd /home/bxg/blockexplorer && /usr/bin/nodejs ./cron/rich.js >> ./tmp/rich.log 2>&1
*/5 * * * * cd /home/bxg/blockexplorer && /usr/bin/nodejs ./cron/coin.js >> ./tmp/coin.log 2>&1
EOL
    crontab mycron
    rm -f mycron
    pm2 start ./server/index.js
    sudo pm2 startup ubuntu
}

# Setup
echo "Updating system..."
sudo apt-get update -y
sudo apt-get install -y apt-transport-https build-essential cron curl gcc git g++ make sudo vim wget
clear

# Variables
echo "Setting up variables..."
bxglink=`curl -s https://api.github.com/repos/blockchain-gold/bxg-wallet/releases/latest | grep browser_download_url | grep linux64 | cut -d '"' -f 4`
rpcuser=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13 ; echo '')
rpcpassword=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '')
echo "Repo: $bxglink"
echo "PWD: $PWD"
echo "User: $rpcuser"
echo "Pass: $rpcpassword"
sleep 5s
clear

# Check for blockexplorer folder, if found then update, else install.
if [ ! -d "/home/bxg/blockexplorer" ]
then
    installNginx
    installMongo
    installWallet
    installNodeAndYarn
    installBlockExplorer
    echo "Finished installation!"
else
    cd /home/bxg/blockexplorer
    git pull
    pm2 restart index
    echo "Block Explorer updated!"
fi

