#!/usr/bin/env bash
<<HEAD
    SCRIPT:
    AUTHOR: Agápito Rojas (agapito.rojas@lasa.com.br)
    DESCRIPTION: Script para atualização do MFE para versão 02.05.09
    VERSION: 1.0 (31/01/2020)
             1.1 (05/02/2020)
    HISTORY:
             1.1 - Inclusão do pack de atualização do PDV.
HEAD

if [ "$(cat /p2k/bin/versaoPDV.dat)" == "14.23.01" ]; then
    echo "PDV na versão 14.23.01, aplicando pack."
    if [ -f /tmp/pack_pdv_p2k.tgz ]; then
        if [ "$(md5sum /tmp/pack_pdv_p2k.tgz |awk '{print $1}' 2>/dev/null)" == "d574f69eadc55a43df0592fc94da21d4" ]; then
            echo "Arquivo OK."
            cd /p2k
            if [ "$(pwd)" == "/p2k" ]; then
                echo "Extraindo pack."
                tar xzvf /tmp/pack_pdv_p2k.tgz
                if [ "$?" -eq "0" ]; then
                    echo "Pack extraído com sucesso."
                    chown -R "p2k:p2k" /p2k
                    chmod -R 777 /p2k
                else
                    echo "Erro descompactando pack."
                    exit 1
                fi
            else
                echo "Diretório /p2k não encontrado."
                exit 1
            fi
        else
            echo "Arquivo do pack com hash diferente."
            exit 1
        fi
    else
        echo "Arquivo do pack não encontrado."
        exit 1
    fi
else
    echo "PDV em versão diferente de 14.23.01."
fi

if [ -f /tmp/instalador-ce-sefaz-driver-linux-x86-02.05.09.tar.gz ]; then
    echo "Verificando arquivo..."
    if [ "$(md5sum /tmp/instalador-ce-sefaz-driver-linux-x86-02.05.09.tar.gz |awk '{print $1}' 2>/dev/null)" == "0aaa953e2de5256a07811fc07096f6a4" ];then
        echo "Arquivo OK."
        echo "Extraindo arquivo..."
        tar xzvf /tmp/instalador-ce-sefaz-driver-linux-x86-02.05.09.tar.gz -C /tmp
        if [ "$?" -eq "0" ]; then
            echo "Arquivo extraído com sucesso. Instalando..."
            if [ -d /tmp/instalador-ce-sefaz-driver-linux-x86-02.05.09 ]; then
                cd /tmp/instalador-ce-sefaz-driver-linux-x86-02.05.09
                if [ -x instala-driver.sh ]; then
                    sh instala-driver.sh
                    if [ "$?" -eq "0" ]; then
                        echo "Instalação com sucesso. Rebootando..."
                        sleep 15
                        shutdown -r now
                    else
                        echo "Erro na instalação."
                        exit 1
                    fi
                else
                    echo "Script de instalação não encontrado."
                    exit 1
                fi
            else
                echo "Diretório do instalaldor não encontrado."
                exit 1
            fi
        else
            echo "Erro na extração do pacote."
            exit 1
        fi
    else
        echo "Pacote com hash MD5 diferente. Abortando."
        exit 1
    fi
else
    echo "Pacote de instalação não encontrado. Abortando."
    exit 1
fi
