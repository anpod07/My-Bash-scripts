#!/bin/sh
# статистика за сегодня
# формат запуска: sh todaystat.sh <IP>
#zcat /usr/local/squid/var/logs/access-old.log.0.0.gz |\
cat /usr/local/squid/var/logs/access-old.log |\
grep -f /usr/local/etc/squid/report/squid_mess | grep -v -f /usr/local/etc/squid/nolimitsites |\
awk '{if ($6=="CONNECT") {print $3 "/" $5 "///" $7};if ($6!="CONNECT") {print $3 "/" $5 "/" $7}}' |\
awk -F/ '{print $1 ";" $2 ";" $5}' |\
awk -F ";" '{pop[$1 ";" $3] += $2}; END {for ( cc in pop ) {print cc ";" pop[cc]}}' |\
awk -F ";" '{print $1,$2,$3}'  > _tstmp.log
cat _tstmp.log | grep "$1 " | awk '{pop[$1] += $3; print $2,$3}; END {for ( cc in pop ) {printf "%s %''d","Total",pop[cc]}}' | sort -rn -k2.2 > todaystat.result
#nice mail -s "OnLine Statistic" nkmz < todaystat.result
rm _tstmp.log
