#!/usr/local/bin/bash
# -------------------------------------------------------------------------------- #
# Формируем файл .htaccess для доступа к файлу proxy.pac на Proxy2 (172.16.31.118) #
# -------------------------------------------------------------------------------- #
cd /home/prx/scripts/proxy_access
# массив IP из squid.conf
arrs=(`grep "^acl .\+ src .\+/32" /usr/local/etc/squid/squid.conf | awk '{print $4}' | awk -F "/" '{print $1}'`)
#echo ${arrs[@]}
# массив IP из ./lists/*
arrl=(`grep "^1" /usr/local/etc/squid/lists/{users_*,ex_*} | awk -F":|/32" '/:.*\/32/{print $2}'`)
#echo ${arrl[@]}
# объединяем массивы
arrall=("${arrs[@]}" "${arrl[@]}")
# формируем файл .htaccess
i=0; :>_res1
for i in "${arrall[@]}"; do
 echo "Require ip $i" >> _res1
done
sort -u _res1 > _res2
#chown www:www _res2
cp _res2 /usr/local/www/default/docs/proxy/.htaccess
rm _res1 _res2
