#!/bin/bash
<<HEADER
    SCRIPT: gera_tab_prisma.sh
    AUTHOR: Agápito Rojas (agapito.rojas@lasa.com.br)
    DESCRIPTION: Script para geração de lista das lojas Prisma no formato "[LOJA];[IP]"
    VERSION:
        1.0 (26/07/2018)
        1.1 (02/01/2018)
        1.2 (03/01/2019)
        1.3 (04/01/2019)
        1.4 (25/06/2020)
    HISTORY:
        v1.1 - Verificação da quantidade de elementos da saída da query
        v1.2 - Criação de segundo array com loja e ip para melhorar a saida
        v1.3 - Alterada query para buscar lojas inauguradas antes de 2017-01-01
        v1.4 - Incluída UF da loja na query e no CSV final, extração do IP movida para função
HEADER

BASE=$(basename $0) ## Nome do script
DBMON="52.31.153.88"
USR="mon_flash"
PASS="monlasa"
LOG="/DSOP/DLOG/${BASE%%.*}.log" ## Arquivo de log
CSV="/DSOP/DTAB/LOJAS_PRISMA.csv"

echo -e "$(date '+%F - %T'): Inicio\n" >>${LOG}

query_loja_uf(){
    if ($(/usr/bin/nc -zw3 ${DBMON} 3306 >/dev/null 2>&1)); then
        #mysql -h ${DBMON} -BN -u${USR} -p${PASS} -e "select loja from monitor_flash.tipo_loja where TIPO_LOJA like '%PRISMA%' and loja in (select loja from lasa.lojas where dt_inauguracao <= '2017-01-01' order by loja ASC)" 2>/dev/null
        while read ROW; do
            set ${ROW}
            LJ=$1
            UF=$2
            IP=$(ver_ip ${LJ})
            echo "${LJ};${IP};${UF}"
        done < <(mysql -h ${DBMON} -BN -u${USR} -p${PASS} -e "select lpad(a.loja,4,0),a.cod_estado from lasa.lojas as a inner join monitor_flash.tipo_loja as b on a.loja = b.loja and b.TIPO_LOJA like '%PRISMA%' and a.loja in (select loja from lasa.lojas where dt_inauguracao <= '2017-01-01' order by loja ASC);" 2>/dev/null)
        ERRO=$?
        if [ ${ERRO} -ne 0 ]; then
            echo "$(date '+%F - %T')- Erro ao acessar a banco." >>${LOG}
            exit 1
        fi
    else
        echo "$(date '+%F - %T')- Erro ao acessar a banco." >>${LOG}
        exit 1
    fi
}

ver_ip(){
    L=$1
    /DSOP/DEXE/ver_end ${L} |cut -f1
}

#query_lojas |xargs -I '{}' /DSOP/DEXE/ver_end '{}' |awk '{OFS = ";"} {print substr($2,5,4),$1}' |tee -a ${LOG} >${TAB}

#array_lojas=($(query_lojas))
#if [ "${#array_lojas[@]}" -gt "0" ]; then
#    for LOJA in ${array_lojas[*]}; do
#        array_loja_ip=(${array_loja_ip[@]} $(/DSOP/DEXE/ver_end ${LOJA} |awk '{OFS = ";"} {print substr($2,5,4),$1}'))
#    done
#    echo ${array_loja_ip[@]} |tr -s ' ' '\n' |tee -a ${LOG} >${TAB}
#else
#    echo "$(date '+%F - %T')- Query não encontrou lojas." >>${LOG}
#    exit 2
#fi

ARRAY_LJIPUF=( $(query_loja_uf) )
if [[ "${#ARRAY_LJIPUF[@]}" -gt "0" ]]; then
    echo "${ARRAY_LJIPUF[@]}" |tr ' ' '\n' |tee -a ${LOG} >${CSV}
else
    echo "$(date '+%F - %T')- Query não encontrou lojas." >>${LOG}
    exit 2
fi

echo -e "\n$(date '+%F - %T'): Fim\n" >>${LOG}
# Fim do Script