#!/usr/local/bin/bash
# ----------------------------------------------------------------------------- #
# Формируем файл .htaccess для доступа к файлу proxy.pac на Proxy (172.16.24.4) #
# ----------------------------------------------------------------------------- #
cd /home/prx/scripts/proxy_access
# массив IP из squid.conf
arrs=(`grep "^acl .\+ src .\+/255.255.255.255 " squid.conf | awk '{print $4}' | awk -F "/" '{print $1}'`)
#echo ${arrs[@]}
# формируем файл .htaccess
i=0; :>_res1; :>_res2
echo "Order Deny,Allow" >> _res2
echo "Deny from All" >> _res2
for i in "${arrs[@]}"; do
 echo "Allow from $i" >> _res1
done
sort -u _res1 >> _res2
chown www:www _res2
cp _res2 /usr/local/www/proxy/.htaccess
rm _res1 _res2
