#!/usr/bin/env bash
<<HEAD
    SCRIPT: 
    AUTHOR: Agápito Rojas (agapito.rojas@lasa.com.br)
    DESCRIPTION: Script de execução do Cashback AME
    VERSION: 1.0 (22/11/2019)
             1.1 (19/12/2019)
    HISTORY: v1.1 - Incluída verificação da hash e coleta do arquivo
HEAD

. /DSOP/DEXE/pusopo12 >/dev/null 2>&1
BASE=$(basename $0)
DESTINATION="/lasa/usr/COMNC/STARX/cashback.txt"
LOG="/DSOP/DLOG/${BASE%%.*}.log"
LOJA=$(hostname |cut -c6-)
SERVER="lxlasa11"
SLEEP=$(echo "${RANDOM} % 31" |bc)
SOURCE="/LOCAL_STATX/ARQUIVOS/AME/cashback.txt"
SSH="ssh -o ConnectTimeout=15 -o UserKnownHostsFile=/dev/null -o PasswordAuthentication=no -o StrictHostKeyChecking=no"

run_cob(){
    export COBSW=-F
    export COBDIR=/opt/microfocus/cobol/
    export LIBPATH=$COBDIR/lib:$LIBPATH:/usr/lib
    cd $CONCENTRADOR
    ./exec/sup01291
}

sleep ${SLEEP}
echo "$(date '+%F %T') - Início" >>${LOG}
LOCAL_HASH=$(md5sum ${DESTINATION} |awk '{print $1}' 2>/dev/null)
REMOTE_HASH=$(su rsync -c "${SSH} lxlasa11 'md5sum ${SOURCE}'" 2>/dev/null |awk '{print $1}')

if [[ ${LOCAL_HASH} = ${REMOTE_HASH} ]]; then
    echo "$(date '+%F %T') - Hash ${LOCAL_HASH} sem alteração." >>${LOG}
elif [[ ${LOCAL_HASH} != ${REMOTE_HASH} ]]; then
    echo "$(date '+%F %T') - Hash local ${LOCAL_HASH} diferente do hash remoto ${REMOTE_HASH}. Baixando o arquivo:" >>${LOG}
    su rsync -c "rsync -vgopz -e '${SSH}' --timeout=30 ${SERVER}:${SOURCE} ${DESTINATION}" >>${LOG} 2>&1 && \
    echo "$(date '+%F %T') - Executando sup01291." >>${LOG}
    run_cob && \
    echo "$(date '+%F %T') - OK" >>${LOG}
fi

echo "$(date '+%F %T') - Fim" >>${LOG}