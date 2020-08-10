#!/usr/bin/env bash
<<HEAD
    SCRIPT:
    AUTHOR: Agápito Rojas (agapito.rojas@lasa.com.br)
    DESCRIPTION: Who The F?ck Is Using My Pts?
    VERSION: 1.0 (13/02/2020)
    HISTORY:
HEAD

for pts in $(find /proc/[0-9]*/fd -type l -exec readlink {} \; 2>/dev/null |awk '/pts\/[0-9]/ {print $1}' |sort -t/ -nk 4 |uniq); do
    echo -e "\e[92m${pts}:\e[0m"
    find /proc/[0-9]*/fd -type l -exec ls -l {} \; 2>/dev/null | \
    awk -v x="${pts}" '/pts/ {for(n=1;n<=NF;n++){if($n == x) print $(n-2)}}' | \
    cut -d/ -f3 |sort |uniq |xargs ps --no-headers -f -p
done