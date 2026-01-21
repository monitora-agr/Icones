#!/usr/bin/bash
#-------------------------------------------------------
# AGTIC
# Script para Backup do GLPIX
# Author: Marcone J. Roque Luna
# Data: 01/01/2025
# Versao: 1.0
# E-mail: comercial@agtic.com.br
# Site: www.agtic.com.br
# Facebook: https://www.facebook.com/AGTICOficial
# Intagram: https://www.instagram.com/agticoficial
# Linkedin: https://www.linkedin.com/company/AGTIC
#-------------------------------------------------------

#Parametros Ajustaveis:
DEST_DIR=/backup
TIMESTAMP=$(date +%Y%m%d%H%M%S)
DB_NAME="glpidb"
MANTER_VERSOES=7

#01. Registrando Log do Inicio da Operacao de Backup do GLPIX.
echo "Registrando Log do Inicio da Operação de Backup do GLPIX..."

logger "Iniciando o Backup do GLPIX..."

#02. Exportando o Banco de Dados do GLPIX.
echo "Exportando o Banco de Dados do GLPIX..."

mysqldump --databases $DB_NAME > /var/www/cstic/glpi/glpi.sql

#03. Copiando as Pastas de Dados e o Banco de Dados do GLPIX.
echo "Copiando as Pastas de Dados e o Banco de Dados do GLPIX..."

tar -cfvz ${DEST_DIR}/GLPI_${TIMESTAMP}.tar.gz \
        /var/www/cstic/config \
        /var/www/cstic/files  \
        /var/www/cstic/glpi   \
        /etc/apache2/sites-available

#04. Removendo Arquivos Temporarios.
echo "Removendo Arquivos Temporarios..."

rm -fr /var/www/cstic/glpi/glpi.sql

#05. Removendo Backups Antigos.
echo "Removendo Backups Antigos..."

skip=0
ls -c $DEST_DIR | while read line; do
        skip=$(($skip + 1));
        if [ $skip -gt $MANTER_VERSOES ]; then
                logger "Removendo Backup Antigo do GLPIX $line"
                rm -fr $DEST_DIR/$line
        fi
done

logger "Finalizada a Operação de Backup do GLPIX."

# Comando para Testar a Quantidade de Backups Salvos.

# for i in $(seq 1 10); do Diretorio/Arquivo; done

# for i in $(seq 1 10); do /script/GLPIX_Backup.sh; done

# Comando para Transferir o Arquivo de Backup entre Servidores.

# scp Diretorio/Arquivo User@0.0.0.0:/Diretorio

# scp backup/GLPIX_YYYYMMDDHHMMSS.tar.gz root@192.51.1.110:/tmp

# Comando para Descompactar Arquivo de Backup.

# tar fvxz Diretorio/Arquivo

# tar fvxz backup/GLPIX_YYYYMMDDHHMMSS.tar.gz