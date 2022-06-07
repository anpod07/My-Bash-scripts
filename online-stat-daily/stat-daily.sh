#!/bin/sh
#----------------------------------------------#
# Общая суточная статистика посещений Интернет #
#----------------------------------------------#
rxhit="TCP_HIT\|TCP_IMS_HIT\|TCP_MEM_HIT\|TCP_NEGATIVE_HIT\|TCP_REFRESH_HIT"
rxmiss="TCP_CLIENT_REFRESH_MISS\|TCP_MISS\|TCP_REFRESH_MISS\|TCP_SWAPFILE_MISS\|TCP_TUNNEL"
zfile=/var/log/squid/access-old.log.0.0.gz
mfile=/var/log/squid/report/`date '+%m-%Y.log'`
cd /root/scripts/online-stat-daily
# Список АКЛ-ов: группы (users_unlim, users_1000, ...), one-site users (squid.conf)
grep "^acl.*src.*/32" /usr/local/etc/squid/squid.conf | awk '{print $4 ";" $2}' | sed -e 's/\/32//g' > _3
cat /usr/local/etc/squid/lists/users_* | tr -d "[:blank:]" | awk -F "/32#" '{print $1 ";" $2}' >> _3
sort -u _3 > _acl
# Приводим access-old.log.?.gz к виду: IP ; URL ; SIZE
zgrep "$rxhit\|$rxmiss" $zfile | awk '{if ($6=="CONNECT") {print $3 "/" $5 "///" $7}; if ($6!="CONNECT") {print $3 "/" $5 "/" $7}}' |\
awk -F/ '{print $1 ";" $2 ";" $5}' | awk -F ";" '{pop[$1 ";" $3] += $2}; END {for (cc in pop) {print cc ";" pop[cc]}}' > _1
# Сталкиваем 2 файла по полю IP-адреса и результат дописываем в файл месячной статистики
awk -F ";" '{if (FILENAME == "_acl") {pop[$1] = $2 " " $1; next} \
if (FILENAME != "_acl" && $3 > 1024) {print pop[$1], $2, $3}}' _acl _1 | sort -k1.1,2 -k4rn >> $mfile
# Пересчитываем объем файла месячной статистики
awk '{pop[$1 " " $2 " " $3] += $4}; END {for (cc in pop) if (pop[cc] > 1024) {print cc, pop[cc]}}' $mfile | sort -k1.1,2 -k4rn > _2
cat _2 > $mfile
rm _1 _acl _2 _3
