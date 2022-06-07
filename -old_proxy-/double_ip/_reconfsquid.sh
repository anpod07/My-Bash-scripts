#!/usr/local/bin/bash
/usr/local/squid/sbin/squid -k reconfigure
#-------------------------------------------------------------------#
# Поиск повторяющихся IP-адрессов в /usr/local/etc/squid/squid.conf #
#-------------------------------------------------------------------#
squf=squid.conf
arrs=(`grep '^acl' $squf | grep "/255.255.255.255 " | awk '{print $4}' | awk -F "/" '{print $1, "1"}' | \
awk '{pop1[$1] += $2} END {for ( cc in pop1 ) {print cc, pop1[cc]}}' | awk '{if ($2 > 1) {print $1}}' | sort`)
# ищем все записи в squid.conf по массиву IP-адрессов
while [ -n "${arrs[i]}" ]
do
 echo "Doubled IPs:"
 grep " ${arrs[i]}/255.255.255.255" $squf
 echo ""
 (( i+=1 ))
done
