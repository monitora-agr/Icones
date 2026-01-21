#==================================================#
#                INSTALAÇÃO DO GLPI                #
#==================================================#
# Author: Marcone J. Roque Luna                    #
#==================================================#
# GNU/Linux Debian 13.1.0                          #
# Apache 2.4.65                                    #
# MariaDB 11.8.3                                   #
# PHP 8.4 + Complementos                           #
# GLPI 11.0.1                                      #
#==================================================#

#01. Atualizando o SO.
echo "01. Atualizando o SO..."

apt update -y
apt upgrade -y

#02. Configurando o Fuso Horario.
echo "02. Configurando o Fuso Horario..."

apt purge ntp
apt install -y openntpd
systemctl stop openntpd
dpkg-reconfigure tzdata
echo "servers pool.ntp.br" > /etc/openntpd/ntpd.conf

systemctl enable openntpd
systemctl start openntpd

#03. Instalando os Pacotes para Manipulação de Arquivos e Outros.
echo "03. Instalando os Pacotes para Manipulação de Arquivos e Outros..."

apt install -y apt-transport-https bsdmainutils bsdutils bzip2 ca-certificates coreutils curl gnupg2 man-db net-tools tree unzip wget xz-utils

#04. Instalando o Apache.
echo "04. Instalando o Apache..."

apt install -y apache2

systemctl enable apache2
systemctl start apache2

#05. Instalando o MariaDB.
echo "05. Instalando o MariaDB..."

apt install -y mariadb-server

systemctl enable mariadb
systemctl start mariadb

#06. Criando o Banco de Dados (glpidb).
echo "06. Criando o Bando de Dados (glpidb)..."

mariadb -e "CREATE DATABASE glpidb CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"

#07. Removendo Usuarios Anônimos.
echo "07. Removendo Usuarios Anônimos..."

mariadb -e "DELETE FROM mysql.user WHERE User='';"

#08. Removendo Acesso Remoto do root.
echo "08. Removendo Acesso Remoto do root..."

mariadb -e "DELETE FROM mysql.user WHERE User='root' AND Host!='localhost';"

#09. Removendo o Banco de Dados (Teste).
echo "09. Removendo o Banco de Dados (Teste)..."

mariadb -e "DROP DATABASE IF EXISTS test;"
mariadb -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';"

#10. Criando o Usuario (glpix) do Banco de Dados.
echo "10. Criando o Usuario (glpix) do Banco de Dados..."

mariadb -e "CREATE USER 'glpix'@'localhost' IDENTIFIED BY 'Senha@12345';"

#11. Concedendo os Privilegios ao Usuario (glpix).
echo "11. Concedendo os Privilegios ao Usuario (glpix)..."

mariadb -e "GRANT ALL PRIVILEGES ON glpidb.* TO 'glpix'@'localhost' WITH GRANT OPTION;"

#12. Forçando a Aplicação dos Privilegios.
echo "12. Forçando a Aplicação dos Privilegios..."

mariadb -e "FLUSH PRIVILEGES;"

systemctl restart mariadb

#13. Habilitando o Suporte ao TimeZone do MariaDB.
echo "13. Habilitando o Suporte ao TimeZone do MariaDB..."

mariadb-tzinfo-to-sql /usr/share/zoneinfo | mariadb -p -u root mysql

#14. Permitindo o Acesso do Usuario (glpix) ao TimeZone.
echo "14. Permitindo o Acesso do Usuario (glpix) ao TimeZone..."

mariadb -e "GRANT SELECT ON mysql.time_zone_name TO 'glpix'@'localhost';"

#15. Forçando a Aplicação dos Privilegios.
echo "15. Forçando a Aplicação dos Privilegios..."

mariadb -e "FLUSH PRIVILEGES;"

systemctl restart mariadb

#16. Instalando o PHP.
echo "16. Instalando o PHP..."

apt install -y php php-{apcu,bcmath,bz2,cli,common,curl,gd,intl,ldap,mbstring,mysql,readline,redis,snmp,soap,xml,xmlrpc,zip}

systemctl restart apache2

#17. Configurando Parâmetros do PHP.
echo "17. Configurando Parâmetros do PHP..."

sed -i 's/^memory_limit = .*/memory_limit = 256M/' /etc/php/8.4/apache2/php.ini
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 32M/' /etc/php/8.4/apache2/php.ini
sed -i 's/^post_max_size = .*/post_max_size = 32M/' /etc/php/8.4/apache2/php.ini
sed -i 's/^max_execution_time = .*/max_execution_time = 600/' /etc/php/8.4/apache2/php.ini
sed -i 's/^;date.timezone =.*/date.timezone = America\/Sao_Paulo/' /etc/php/8.4/apache2/php.ini
sed -i 's/^;session.cookie_httponly =.*/session.cookie_httponly = On/' /etc/php/8.4/apache2/php.ini

systemctl restart apache2

#18. Instalando o GLPI.
echo "18. Instalando o GLPI..."

cd /tmp
wget https://github.com/glpi-project/glpi/releases/download/11.0.1/glpi-11.0.1.tgz
tar -zxvf glpi-11.0.1.tgz
mv glpi /var/www/html
rm glpi-11.0.1.tgz
cd /

#19. Alterando a Propriedade dos Arquivos do GLPI.
echo "19. Alterando a Propriedade dos Arquivos do GLPI..."

chown -fR www-data:www-data /var/www/html/glpi
find /var/www/html/glpi -type d -exec chmod 755 {} \;
find /var/www/html/glpi -type f -exec chmod 644 {} \;

#20. Criando o Arquivo de Configuração do Apache para o GLPI.
echo "20. Criando o Arquivo de Configuração do Apache para o GLPI..."

cat > /etc/apache2/conf-available/glpi.conf << EOF
<VirtualHost *:80>

     ServerName host.dominio.com.br
     ServerAdmin user@dominio.com.br
     DocumentRoot /var/www/html/glpi/public
     ErrorLog \${APACHE_LOG_DIR}/glpi.error.log
     CustomLog \${APACHE_LOG_DIR}/glpi.access.log combined

     <Directory "/var/www/html/glpi/public/">

          AllowOverride All
          Require all granted
          RewriteEngine On
          RewriteCond %{REQUEST_FILENAME} !-f
          RewriteRule ^(.*)$ index.php [QSA,L]

     </Directory>
</VirtualHost>
EOF

export PATH=$PATH:/usr/sbin:/sbin
a2enmod rewrite
a2enconf glpi.conf
systemctl reload apache2

#21. Configurando o Banco de Dados (glpidb) do GLPI.
echo "21. Configurando o Banco de Dados (glpidb) do GLPI..."

php /var/www/html/glpi/bin/console glpi:database:install -L'pt_BR' -H'localhost' -d'glpidb' -u'glpix' -p'Senha@12345' --allow-superuser --force --no-telemetry

#22. Instalando o REDIS (Cache).
echo "22. Instalando o REDIS (Cache)..."

apt install -y redis

#23. Configurando o REDIS (Cache).
echo "23. Configurando o REDIS (Cache)..."

php /var/www/html/glpi/bin/console cache:configure --allow-superuser --context=core --dsn=redis://127.0.0.1:6379

#24. Criando Entrada no Agendador de Tarefas.
echo "24. Criando Entrada no Agendador de Tarefas..."

echo -e "* *\t* * *\troot\tphp /var/www/html/glpi/front/cron.php" >> /etc/crontab

systemctl restart cron

#25. Removendo o Arquivo de Instalação do GLPI.
echo "25. Removendo o Arquivo de Instalação do GLPI..."

rm -fR /var/www/html/glpi/install/install.php
chown -R www-data:www-data /var/www/html/glpi

echo "##################################################"
echo "# FINALIZADO O PROCESSO DE INSTALAÇÃO DO GLPI 11 #"
echo "##################################################"

#Acessar o endereço http://IPdoServidor, para iniciar o uso do GLPI.
echo "Acessar o endereço http://IPdoServidor, para iniciar o uso do GLPI."

echo "###########################################################################"
echo "# Ao realizar o 1º LogIn no GLPI, executar as seguintes ações (Opcionais):#"
echo "###########################################################################"

echo "1. Alterar o Nome, Senha, E-mail e Perfil Padrão do User: glpi."
echo "2. Colocar na Lixeira os Users: normal, post-only e tech."
echo "3. Definir a Senha do root do Banco de Dados."

echo "###########################################################################"
echo "# mariadb -u root -p                                                      #"
echo "# Enter                                                                   #"
echo "#                                                                         #"
echo "# ALTER USER 'root'@'localhost' IDENTIFIED BY 'Digite a Senha Aqui';      #"
echo "#                                                                         #"
echo "# FLUSH PRIVILEGES;                                                       #"
echo "#                                                                         #"
echo "# EXIT;                                                                   #"
echo "###########################################################################"