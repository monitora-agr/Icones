#!/bin/bash
#-------------------------------------------------------
# AGTIC
# Script para Atualização do GLPIX
# Author: Marcone J. Roque Luna
# Data: 01/01/2025
# Versao: 1.0
# E-mail: comercial@agtic.com.br
# Site: www.agtic.com.br
# Facebook: https://www.facebook.com/AGTICOficial
# Intagram: https://www.instagram.com/agticoficial
# Linkedin: https://www.linkedin.com/company/AGTIC
#-------------------------------------------------------

echo "Iniciando a Atualização do GLPIX..."

#01. Atualizando o SO.
echo "Atualizando o SO..."

apt-get update
apt-get upgrade -y

#02. Parando o Serviço Cron.
echo "Parando o Serviço Cron..."

systemctl stop cron

#03. Alterando o Nome da Pasta do GLPIX.
echo "Alterando o Nome da Pasta do GLPIX..."

cd /var/www/cstic
mv glpi glpi.old

#04. Fazendo o Download do GLPIX.
echo "Fazendo o Download do GLPIX..."

wget -O- https://github.com/glpi-project/glpi/releases/download/10.0.19/glpi-10.0.19.tgz | tar -vxz -C /var/www/cstic/

#05. Copiando os Diretorios Pics e Plugins do GLPIX.
echo "Copiando os Diretorios Pics e Plugins do GLPIX..."

cp glpi.old/pics/* glpi/pics -fR
cp glpi.old/plugins/* glpi/plugins -fR

#06. Removendo os Diretorios Config e Files do GLPIX.
echo "Removendo os Diretorios Config e Files do GLPIX..."

rm glpi/config -fR
rm glpi/files -fR

#07. Alterando o Caminho dos Diretorios Config e Files do Diretorio GLPI do GLPIX.
echo "Alterando o Caminho dos Diretorios Config e Files do Diretorio GLPI do GLPIX..."

sed -i 's/\/config/\/..\/config/g' /var/www/cstic/glpi/inc/based_config.php
sed -i 's/\/files/\/..\/files/g' /var/www/cstic/glpi/inc/based_config.php

#08. Atribuindo Propriedade para o User www.data no GLPIX.
echo "Atribuindo Propriedade para o User www.data no GLPIX..."

chown www-data:www-data config -fR
chown www-data:www-data files -fR
chown www-data:www-data glpi -fR

#09. Atribuindo Permissões para os Arquivos e Diretorios do GLPIX.
echo "Atribuindo Permissões para os Arquivos e Diretorios do GLPIX..."

find glpi -type d -exec chmod 755 {} \;
find glpi -type f -exec chmod 644 {} \;

#10. Iniciando o Serviço Cron.
echo "Iniciando o Serviço Cron..."

systemctl start cron

echo "Atualização Finalizada com Sucesso."

echo "Agora acesse https://IPdoServidorGLPI, para iniciar o uso do GLPIX."

echo "Ao confirmar o processo de Atualização, excluir o arquivo install.php em /var/www/cstic/glpi/install/install.php."

echo "Alterar a Diretiva PHP "session.cookie_httponly" para "on" em /etc/php/8.X/apache2/php.ini"