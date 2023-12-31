#!/bin/bash
# 
# functions for setting up app backend

#######################################
# creates mysql db using docker
# Arguments:
#   None
#######################################
# backend_mysql_create() {
#   print_banner
#   printf "${WHITE} 💻 Criando banco de dados...${GRAY_LIGHT}"
#   printf "\n\n"

#   sleep 2

#   sudo su - root <<EOF
#   usermod -aG docker ${$deploy_user}
#   docker run --name whaticketdb \
#                 -e MYSQL_ROOT_PASSWORD=${mysql_root_password} \
#                 -e MYSQL_DATABASE=${db_name} \
#                 -e MYSQL_USER=${db_user} \
#                 -e MYSQL_PASSWORD=${db_pass} \
#              --restart always \
#                 -p 3306:3306 \
#                 -d mariadb:latest \
#              --character-set-server=utf8mb4 \
#              --collation-server=utf8mb4_bin
# EOF

#   sleep 12
# }

#######################################
# creates mysql db using docker
# Arguments:
# Function to create a sample database and table, and insert a record
#######################################
backend_mysql_create() {
#    local db_user="your_mysql_user"
#    local db_password="your_mysql_password"
#    local db_name="sample_db"

#    local table_name="sample_table"
#    USE $db_name;
# ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY ${mysql_root_password};
 
   print_banner
   printf "${WHITE} 💻 Criando banco de dados MYSQL ${db_name}...${GRAY_LIGHT}"
   printf "\n\n"

   sleep 2

#   apt update
#   apt install -y mysql-server

# Iniciar o MySQL
#  systemctl start mysql
#  systemctl enable mysql
# if [ $? -eq 0 ]; then
 #      echo "O Usuário ${db_name} MySQL criado com sucesso."
 # else
 #      echo "Ocorreu um erro ao criar o usuário ${db_name} MySQL."
 # fi
# Comando SQL para criar o usuário
 #SQL_QUERY="CREATE USER '${db_user}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${db_pass}';"

  mysql -u root -pjjagf -e "CREATE USER '${db_user}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${db_pass}';"

  mysql -u root -pjjagf -e "CREATE DATABASE ${db_name};"
 
  mysql -u root -pjjagf <<EOF
  GRANT ALL PRIVILEGES ON *.* TO '${db_user}'@'localhost';
  FLUSH PRIVILEGES;

EOF

   printf "${WHITE} 💻 Testando banco de dados MYSQL ${db_name}...${GRAY_LIGHT}"
   printf "\n\n"
 

   sleep 12

}


#######################################
# sets environment variable for backend.
# Arguments:
#   None
#######################################
backend_set_env() {
  print_banner
  printf "${WHITE} 💻 Configurando variáveis de ambiente (backend)..${deploy_user}.${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # ensure idempotency
  backend_url=$(echo "${backend_url/https:\/\/}")
  backend_url=${backend_url%%/*}
  backend_url=https://$backend_url

  # ensure idempotency
  frontend_url=$(echo "${frontend_url/https:\/\/}")
  frontend_url=${frontend_url%%/*}
  frontend_url=https://$frontend_url

sudo su - ${deploy_user} << EOF
  cat <<[-]EOF > /home/${deploy_user}/whaticket/backend/.env
NODE_ENV=
BACKEND_URL=${backend_url}
FRONTEND_URL=${frontend_url}
PROXY_PORT=443
PORT=7773

DB_HOST=127.0.0.1
DB_DIALECT=
DB_USER=${db_user}
DB_PASS=${db_pass}
DB_NAME=${db_name}

JWT_SECRET=${jwt_secret}
JWT_REFRESH_SECRET=${jwt_refresh_secret}
[-]EOF
EOF

  sleep 12
}

#######################################
# installs node.js dependencies
# Arguments:
#   None
#######################################
backend_node_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando dependências  backend.${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket/backend
  npm install
EOF

  sleep 12
}

#######################################
# compiles backend code
# Arguments:
#   None
#######################################
backend_node_build() {
  print_banner
  printf "${WHITE} 💻 Compilando o código do backend.${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user}<<EOF
  cd /home/${deploy_user}/whaticket/backend
  npm install
  npm run build
EOF

  sleep 12
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_update() {
  print_banner
  printf "${WHITE} 💻 Atualizando o backend.${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket
  git pull
  cd /home/${deploy_user}/whaticket/backend
  npm install
  rm -rf dist 
  npm run build
  npx sequelize db:migrate
  npx sequelize db:seed
  pm2 restart all
EOF

  sleep 2
}

#######################################
# runs db migrate
# Arguments:
#   None
#######################################
backend_db_migrate() {
  print_banner
  printf "${WHITE} 💻 Executando db:migrate.${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket/backend
  npx sequelize db:migrate
EOF

  sleep 12
}

#######################################
# runs db seed
# Arguments:
#   None
#######################################
backend_db_seed() {
  print_banner
  printf "${WHITE} 💻 Executando db:seed.${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket/backend
  npx sequelize db:seed:all
EOF

  sleep 12
}

#######################################
# starts backend using pm2 in 
# production mode.
# Arguments:
#   None
#######################################
backend_start_pm2() {
  print_banner
  printf "${WHITE} 💻 Iniciando pm2 (backend).${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - ${deploy_user} <<EOF
  cd /home/${deploy_user}/whaticket/backend
  pm2 start dist/server.js --name whaticket-backend
EOF

  sleep 12
}

#######################################
# updates frontend code
# Arguments:
#   None
#######################################
backend_nginx_setup() {
  print_banner
  printf "${WHITE} 💻 Configurando nginx (backend).${deploy_user}..${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_hostname=$(echo "${backend_url/https:\/\/}")

sudo su - root << EOF

cat > /etc/nginx/sites-available/whaticket-backend << 'END'
server {
  server_name $backend_hostname;

  location / {
    proxy_pass http://127.0.0.1:7773;
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

ln -s /etc/nginx/sites-available/whaticket-backend /etc/nginx/sites-enabled
EOF

  sleep 12
}