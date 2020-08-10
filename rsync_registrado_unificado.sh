#!/usr/bin/env ksh
####################################################################################################
#
#       Script de integracao de arquivos Resgistrados do Prisma e P2K com Tesouraria (Midas/legado)
#       Autor: Agapito Rojas (agapito.rojas@lasa.com.br)
#
#       Versao 1.0 (11/04/2020)
#
####################################################################################################

BASE=`basename $0` ## Nome do script
DIRBKP="/RSYNC/ARCHIVE/TESOURARIA" ## Diretorio de backup
DIRFS="/RSYNC/P2K/EP" ## NFS para o LXLASAFS01
DIRMIDAS="/var/tesouraria/files/filewatcher/current" ## Diretorio remoto do Midas
DIRSTATX="/lasa/usr/COMNC/STATX/PI" ## Diretorio remoto na loja
DIRTES="/RSYNC/IBMFARM01/TESOURARIA" ## NFS para o IBMFARM01
DIRTXMIDAS="/RSYNC/MIDAS/TX" ## Diretorio de transmissao para Midas
LISTAPRISMA="/DSOP/DTAB/LOJAS_PRISMA.csv" ## Lista de lojas Prisma
LOG="/DSOP/DLOG/${BASE%%.*}.log" ## Log com base no nome do script
MLOG="/DSOP/DLOG/${BASE%%.*}_midas.log" ## Log de lojas Midas
PIDFILE="/DSOP/DLOG/${BASE%%.*}.pid" ## Arquivo de PID
SSH="ssh -q -o ConnectTimeout=15 -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o StrictHostKeyChecking=no"
SRVMIDAS="10.223.2.182" ## IP do servidor do Midas
USRMIDAS="ftpman" ## Usuario remoto do Midas
## Variaveis SQL
SQLSRV="52.31.153.88"
SQLUSR="mon_flash"
SQLPWD="monlasa"

function verifica_pid {
	if [ -s ${PIDFILE} ]; then
		LASTPID=$(cat ${PIDFILE})
		if [ -d /proc/${LASTPID} ]; then
			echo "`date \"+%F %T\"` - Processo em execucao." >>${LOG} 2>&1
			exit 0
		else
			echo $$ >${PIDFILE}
		fi
	else
		echo $$ >${PIDFILE}
	fi
}

function coleta_p2k {
    
}

function coleta_prisma {
    LOJA=$1
    ORIGEM=$2
    echo "LOJA ${LOJA} MIDAS\n"
    rsync -cgop -e "${SSH}" --include='[lL][fF][iI][nN]*' --include='[lL][oO][uU][tT]*' --include='[lL][rR][iI][nN]*' --include='[lL][vV][dD][eE][pP]*' --include='[tT][eE][sS]*' --exclude='*' --timeout=30 ${ORIGEM}/* ${DIRBKP} && \
    rsync -cgop -e "${SSH}" --include='[lL][fF][iI][nN]*' --include='[lL][oO][uU][tT]*' --include='[lL][rR][iI][nN]*' --include='[lL][vV][dD][eE][pP]*' --include='[tT][eE][sS]*' --exclude='*' --timeout=30 ${ORIGEM}/* ${DIRTXMIDAS} && \
    rsync -cgopv -e "${SSH}" --include='[lL][fF][iI][nN]*' --include='[lL][oO][uU][tT]*' --include='[lL][rR][iI][nN]*' --include='[lL][vV][dD][eE][pP]*' --include='[tT][eE][sS]*' --exclude='*' --remove-source-files --timeout=30 ${ORIGEM}/* ${DIRTES} && \
    ERRO=$?
    if [ ${ERRO} -eq 0 ]; then
        echo "\n`date \"+%F %T\"` - OK\n"
    else
        echo "\n`date \"+%F %T\"` - ERRO ${ERRO}\n"
    fi
}

function transmite_midas {
    echo "`date \"+%F %T\"` - Transmitindo arquivos para o Midas:"
    rsync -cgopv --include='[lL][fF][iI][nN]*' --include='[lL][oO][uU][tT]*' --include='[lL][rR][iI][nN]*' --include='[lL][vV][dD][eE][pP]*' --include='[tT][eE][sS]*' --exclude='*' --remove-source-files --timeout=30 ${DIRTXMIDAS}/* ${USRMIDAS}@${SRVMIDAS}:${DIRMIDAS}
    ERRO=$?
    if [ ${ERRO} -eq 0 ]; then
        echo "\n`date \"+%F %T\"` - Arquivos transmitidos com sucesso.\n"
    else
        echo "\n`date \"+%F %T\"` - ERRO ${ERRO} na transmissao para o Midas.\n"
    fi
}

function query_lojas_prisma {
    if (`ncat -vzw5 52.31.153.88 3306 >/dev/null 2>&1`); then
        mysql -h ${SQLSRV} -BN -u${SQLUSR} -p${SQLPWD} -e "select loja from monitor_flash.tipo_loja where TIPO_LOJA like '%PRISMA%' and loja in (select loja from lasa.lojas where dt_inauguracao <= '2017-01-01' order by loja ASC)" 2>/dev/null
    else
        echo "`date \"+%F %T\"` - Erro ao acessar o banco."
    fi
}