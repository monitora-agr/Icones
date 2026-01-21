#!/usr/bin/bash
#-------------------------------------------------------
# AGTIC
# Script para Instalação do GLPIX
# Author: Marcone J. Roque Luna
# Data: 01/01/2025
# Versao: 1.0
# E-mail: comercial@agtic.com.br
# Site: www.agtic.com.br
# Facebook: https://www.facebook.com/AGTICOficial
# Intagram: https://www.instagram.com/agticoficial
# Linkedin: https://www.linkedin.com/company/AGTIC
#-------------------------------------------------------

#01. Atualizando o SO.
echo "Atualizando o SO."

apt-get update -y
apt-get upgrade -y

#02. Configurando os Fusos Horarios no GLPIX.
echo "Configurando os Fusos Horarios do GLPIX..."

apt-get purge ntp
apt-get install openntpd -y
systemctl stop openntpd
dpkg-reconfigure tzdata
echo "servers pool.ntp.br" > /etc/openntpd/ntpd.conf
systemctl enable openntpd
systemctl start openntpd

#03. Instalando os Pacotes para Manipulação de Arquivos e Outras Coisas.
echo "Instalando os Pacotes para Manipulação de Arquivos e Outras Coisas..."

apt-get install bsdmainutils bsdutils bzip2 coreutils curl man-db net-tools tree unzip wget xz-utils -y 

#04. Preparando o Servidor Web.
echo "Preparando o Servidor Web..."

apt-get install apache2 libapache2-mod-php php-soap php-cas php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,redis,bz2} -y

#05. Resolvendo o Problema de Acesso Web ao Diretorio.
echo "Resolvendo o Problema de Acesso Web ao Diretorio..."

cat > /etc/apache2/conf-available/cstic.conf << EOF
<Directory "/var/www/cstic/glpi/public/">

     AllowOverride All
     RewriteEngine On
     RewriteCond %{REQUEST_FILENAME} !-f
     RewriteRule ^(.*)$ index.php [QSA,L]
     Options -Indexes
     Options -Includes -ExecCGI
     Require all granted

     <IfModule mod_php7.c>
          php_value max_execution_time 600
          php_value always_populate_raw_post_data -1
     </IfModule>

     <IfModule mod_php8.c>
          php_value max_execution_time 600
          php_value always_populate_raw_post_data -1
     </IfModule>

</Directory>
EOF

a2enmod rewrite
a2enconf cstic.conf
systemctl restart apache2

#06. Criando o Diretorio do GLPIX.
echo "Criando o Diretorio do GLPIX..."

mkdir /var/www/cstic

#07. Baixando e Instalando o GLPIX.
echo "Baixando e Instalando o GLPIX..."

wget -O- https://github.com/glpi-project/glpi/releases/download/10.0.20/glpi-10.0.20.tgz | tar -vxz -C /var/www/cstic/

#08. Movendo os Diretorios Config e Files para fora do Diretorio do GLPIX.
echo "Movendo os Diretoriso Config e Files para fora do Diretorio do GLPIX..."

mv /var/www/cstic/glpi/config /var/www/cstic/
mv /var/www/cstic/glpi/files /var/www/cstic/

#09. Alterando o Codigo do GLPIX para o Novo Local dos Diretorios Config e Files.
echo "Alterando o Codigo do GLPIX para o Novo Local dos Diretorios Config e Files."

sed -i 's/\/config/\/..\/config/g' /var/www/cstic/glpi/inc/based_config.php
sed -i 's/\/files/\/..\/files/g' /var/www/cstic/glpi/inc/based_config.php

#10. Alterando a Propriedade dos Arquivos da Pasta do GLPIX.
echo "Alterando a Propriedade dos Arquivos da Pasta do GLPIX..."

chown root:root /var/www/cstic/glpi -fR

#11. Alterando a Propriedade dos Arquivos Config, Files e Marketplace.
echo "Alterando a Propriedade dos Arquivos Config, Files e Marketplace..."

chown www-data:www-data /var/www/cstic/config -fR
chown www-data:www-data /var/www/cstic/files -fR
chown www-data:www-data /var/www/cstic/glpi/marketplace -fR

#12. Alterando as Permissões Gerais.
echo "Alterando as Permissões Gerais..."

find /var/www/cstic/ -type d -exec chmod 755 {} \;
find /var/www/cstic/ -type f -exec chmod 644 {} \;

#13. Instalando o Banco de Dados (MariaDB).
echo "Instalando o Banco de Dados (MariaDB)..."

apt-get install mariadb-server -y

#14. Criando o Banco de Dados (glpidb).
echo "Criando o Bando de Dados (glpidb)..."

mysql -e "create database glpidb character set utf8"

#15. Criando o Usuario (glpi) do Banco de Dados.
echo "Criando o Usuario (glpi) do Banco de Dados..."

mysql -e "create user 'glpi'@'localhost' identified by 'Senha@12345'"

#16. Concedendo os Privilegios ao Usuario (glpi).
echo "Concedendo os Privilegios ao Usuario (glpi)..."

mysql -e "grant all privileges on glpidb.* to 'glpi'@'localhost' with grant option";

#17. Habilitando o Suporte ao TimeZone do MySQL/MariaDB.
echo "Habilitando o Suporte ao TimeZone do MySQL/MariaDB..."

mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -p -u root mysql

#18. Permitindo o Acesso do Usuario (glpi) ao TimeZone.
echo "Permitindo o Acesso do Usuario (glpi) ao TimeZone..."

mysql -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'localhost';"

#19. Forçando a Aplicação dos Privilegios.
echo "Forçando a Aplicação dos Privilegios..."

mysql -e "FLUSH PRIVILEGES;"

#20. Configurando o Banco de Dados do GLPIX.
echo "Configurando o Banco de Dados do GLPIX..."

php /var/www/cstic/glpi/bin/console glpi:database:install --default-language=pt_BR --db-host=localhost --db-name=glpidb --db-user=glpi --db-password='Senha@12345' --force

#21. Criando Entrada no Agendador de Tarefas.
echo "Criando Entrada no Agendador de Tarefas..."

echo -e "* *\t* * *\troot\tphp /var/www/cstic/glpi/front/cron.php" >> /etc/crontab
systemctl restart cron

#22. Removendo o Arquivo de Instalação do GLPIX.
echo "Removendo o Arquivo de Instalação do GLPIX..."

rm -fR /var/www/cstic/glpi/install/install.php

#23. Instalando o REDIS (Cache).
echo "Instalando o REDIS (Cache)..."

apt install redis -y
php /var/www/cstic/glpi/bin/console cache:configure --context=core --dsn=redis://127.0.0.1:6379

#24. Publicando o Site do GLPIX.
echo "Publicando o Site do GLPIX..."

cat > /etc/apache2/sites-available/cstic.conf << EOF
<VirtualHost *:80>

        ServerName cstic.dominio.com.br
        ServerAdmin cstic@dominio.com.br
        DocumentRoot /var/www/cstic/glpi/public

        ErrorLog \${APACHE_LOG_DIR}/glpi.error.log
        CustomLog \${APACHE_LOG_DIR}/glpi.access.log combined

</VirtualHost>
EOF

a2ensite cstic.conf
systemctl restart apache2
a2dissite 000-default.conf
systemctl reload apache2

#25. Acessar o endereço http://IPdoServidor, para iniciar o uso do GLPIX.
echo "Acessar o endereço http://IPdoServidor, para iniciar o uso do GLPIX."

echo "Antes de iniciar a configuração, realize as seguintes configurações iniciais no GLPIX."

echo "1. Acessar a linha: session.cookie_httponly = "on" (/etc/php/8.X/apache2/php.ini)."
echo "2. Adicionar o User www-data como Owner do arquivo /var/www/cstic/files/_log/php-errors.log.
echo "3. Alterar o Nome, Senha, E-mail e definir o Perfil Padrão da conta glpi."
echo "4. Colocar na Lixeira as contas normal, post-only e tech."
echo "5. Definir o Posicionamento do Menu como Horizontal."