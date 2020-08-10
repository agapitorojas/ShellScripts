#!/usr/bin/env bash
<<HEAD
    SCRIPT:
    AUTHOR: Agápito Rojas (agapito.rojas@lasa.com.br)
    DESCRIPTION: Script para transporte de arquivos entre nps_b2w (SFTP) e LASAMN02
    VERSION: 1.0 (13/02/2020)
    HISTORY:
HEAD

base="$(basename $0)"
ctrl_md5="/DSOP/DLOG/${base%%.*}_ctrl_md5"
log="/DSOP/DLOG/${base%%.*}.log"
pidfile="/var/run/${base%%.*}.pid"
nfs_in="/nfs/lasasmn02_nps_in"
nfs_out="/nfs/lasasmn02_nps_out"
sftp_get="/lasa/home/nps_b2w/get"
sftp_put="/lasa/home/nps_b2w/put"
statxdir="/LOCAL_STATX/ARQUIVOS/SFTP/nps_b2w"

verifica_pid(){
    if [ -f ${pidfile} ]; then
        oldpid=$(cat ${pidfile})
		if [ -d /proc/${oldpid} ]; then
			echo "$(date '+%F %T') - Processo em execucao." >>${LOG} 2>&1
			exit 0
		else
			echo $$ >${pidfile}
		fi
	else
		echo $$ >${pidfile}
	fi
}

echo "$(date '+%F %T') - Início" >>${LOG}
verifica_pid

for file in $(find ${nfs_out} -maxdepth 1 -type f -name "LASA_????????.txt"); do
	md5="$(md5sum ${file} 2>/dev/null| awk '{print $1}')"
	md5ctrl="$(grep -w ${file} ${ctrl_md5} |tail -1 2>/dev/null |awk '{print $1}')"
	if [[ "${md5}" != "${md5ctrl}" ]]; then
		cp -v ${file} ${statxdir}
		if [[ "$?" -eq "0" ]]; then
			echo "${md5} ${file} $(date '+%F %T')" >>${ctrl_md5}
		else
			echo "$(date '+%F %T') ERRO: ${file}"
		fi
	fi
done

if [[ "$(find ${statxdir} -maxdepth 1 -type f -name 'LASA_????????.txt' |wc -l)" -gt "0" ]]; then
	echo "$(date '+%F %T'): Transmitindo para o SFTP"
	rsync -vgopz --remove-sent-files --timeout=30 ${statxdir}/* lasaftp2:${sftp_get} >>${log} 2>&1
	if [[ "$?" -eq "0" ]]; then
		echo "$(date '+%F %T'): Arquivos transmitidos com sucesso" >>${log} 2>&1
	else
		echo "$(date '+%F %T') ERRO: exit $?" >>${log} 2>&1
	fi
else
	echo "$(date '+%F %T'): Sem arquivos para transmitir" >>${log} 2>&1
fi

echo "$(date '+%F %T') - Fim" >>${LOG}
rm -f ${pidfile} >/dev/null 2>&1

#Fim do script