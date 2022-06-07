#!/usr/local/bin/bash
# ===================================================================================================================== #
# Активность почтовых аккаунтов из списка ненайденных в hosts.
# Перед запуском скрипта нужно:
# 	- создать директории ./mess и ./temp
#	- скопировать файлы: /var/log/messages* -> ./mess/, /etc/mail/aliases -> ./mess/, /etc/master.passwd -> ./mess/
# Результате работы скрипта будут в директории ./temp
# ===================================================================================================================== #
cd /root/scripts/actualize/2_from_hosts
arr=(`awk '{print $2}' _check | awk -F ";" '{print $1}' | sort`)
#echo ${arr[*]}
i=0; j=0;
while [ -n "${arr[i]}" ]
do
 grep "${arr[i]}" ./mess/aliases > ./temp/${arr[i]}
 grep "${arr[i]}" ./mess/master.passwd >> ./temp/${arr[i]}
 grep " ${arr[i]} " ./mess/messages >> ./temp/${arr[i]}
 zgrep " ${arr[i]} " ./mess/messages.*.gz >> ./temp/${arr[i]}
 (( i++ ))
done
