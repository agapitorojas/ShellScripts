#!/usr/bin/env bash
<<HEAD
    SCRIPT:
    AUTHOR: Agápito Rojas (agapito.rojas@lasa.com.br)
    DESCRIPTION: Script de execução do coletado AME
    VERSION: 1.0 (23/11/2019)
    HISTORY:
HEAD

. /DSOP/DEXE/pusopo12 >/dev/null 2>&1
base=$(basename $0)
log="/DSOP/DLOG/${base%%.*}.log"
loja=$(hostname |cut -c6-)

run_cob(){
    export COBSW=-F
    export COBDIR=/opt/microfocus/cobol/
    export LIBPATH=$COBDIR/lib:$LIBPATH:/usr/lib
    cd $CONCENTRADOR
    ./exec/sup01293
}

echo "$(date '+%F %T') - Início" >>${log}
run_cob >>${log} 2>&1
echo "$(date '+%F %T') - Fim" >>${log}
