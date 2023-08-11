#!/bin/bash
# 
# functions for setting up app frontend

#######################################
# installed node packages
# Arguments:
#   None
#######################################
frontend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências do frontend.${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket/frontend
  npm install
EOF

  sleep 10
}

#######################################
# compiles frontend code
# Arguments:
#   None
#######################################
frontend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do frontend...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket/frontend
  npm install
  npm run build
EOF

  sleep 10
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
frontend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o frontend.${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket
  git pull
  cd /home/${deploy_user}/whaticket/frontend
  npm install
  rm -rf build
  npm run build
  pm2 restart all
EOF

  sleep 10
}


#######################################
# sets frontend environment variables
# Arguments:
#   None
#######################################
frontend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente ${deploy_user} (frontend)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

sudo su - ${deploy_user} << EOF
  cat <<[-]EOF > /home/${deploy_user}/whaticket/frontend/.env
REACT_APP_BACKEND_URL=${backend_url}
[-]EOF
EOF

  sleep 10
}

#######################################
# starts pm2 for frontend
# Arguments:
#   None
#######################################
frontend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (frontend).${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket/frontend
  pm2 start server.js --name whaticket-frontend
  pm2 save
EOF

  sleep 10
}

#######################################
# sets up nginx for frontend
# Arguments:
#   None
#######################################
frontend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (frontend).${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  frontend_hostname=$(echo "${frontend_url/https:\/\/}")

sudo su - root << EOF

cat > /etc/nginx/sites-available/whaticket-frontend << 'END'
server {
  server_name $frontend_hostname;

  location / {
    proxy_pass http://127.0.0.1:8081;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_cache_bypass \$http_upgrade;
  }
}
END

ln -s /etc/nginx/sites-available/whaticket-frontend /etc/nginx/sites-enabled
EOF

  sleep 10
}
