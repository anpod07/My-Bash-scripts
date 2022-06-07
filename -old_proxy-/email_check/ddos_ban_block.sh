#!/usr/local/bin/bash
# Добавление запрещающих правил в IPFW по списку DDOS-ров и BAN-ров
#datlog=`stat -f "%Sm" -t "%Y-%m-%d" $mesf`
#logf=`echo block_$datlog`
logf=block_2019-08-15
#---#
#arrb=(`awk '{print $6}' ./logs/$logf-ban.log | sort -u`)	# массив IP-адресов для запрета
arrb=(172.16.41.252 172.16.41.253)
echo ${arrb[*]}
b=10		# счетчик для нумерации правил IPFW, начинаем с правила 2010
while [ -n "${arrb[i]}" ]	# создание запрещающий правил
do
 /sbin/ipfw -q add 20$b deny ip from ${arrb[i]} to 172.16.31.117 25,110,119,465,995 setup
 echo "Rule 20$b - banned ${arrb[i]}"
 (( i+=1 ))
 (( b+=1 )) 
done
