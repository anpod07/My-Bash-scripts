#!/usr/local/bin/bash
#========================================================#
# Online SQUID monitoring by user's SIZE, SPEED and HITS #
#========================================================#
cd /usr/home/ivan/online/squid_online_monitor
i=0; j=1; t1=0; t2=0; t3=0; s=0; inp=""; kn=0
flog="/usr/local/squid/var/logs/access-old.log"
rm _1 _2
# выбор режима сортировки: общий ОБЪЕМ (Кбайт) скачанного пользователем, средняя СКОРОСТЬ (Кбит/с) загрузки канала, КОЛ-ВО ЗАПРОСОВ от пользователя
while [ "$inp" != "1" -a "$inp" != "2" -a "$inp" != "3" ]
do
 echo -n "Choose SORT: by Data Volume (1), by Avr Speed (2), by Hits (3): "
 read inp
 case $inp in
  "1" ) kn=2 ;;
  "2" ) kn=4 ;;
  "3" ) kn=6 ;;
  * ) echo "You entered some shit. Repeat" ;;
 esac
done
while [ "$i" -lt "$j" ]			# бесконечный цикл
do
 t1=`cat $flog | wc -l`			# t1: текущее кол-во строк файла
 ((t3=$t1-$t2))				# t3: кол-во строк снизу файла, которые обрабатываются
 if [ $t3 -eq $t1 ]; then t3=0; fi	# игнор первой итерации, т.к. еще t2 = 0
 t2=$t1					# t2: кол-во строк без учета новых появившихся, которое вычитается из t1 для получения t3
# Формируем и ежесекундно дополняем список активных на данный момент пользователей SQUID, вычисляем КОЛ-ВО ЗАПРОСОВ от пользователя
 tail -n $t3 $flog | awk '{print $3, $5}' |\
 awk '{pop[$1]+=$2; pop2[$1]+=1}; END {for (cc in pop) if (pop[cc]>0) {print cc, pop[cc], pop2[cc]}}' >> _1
# Вычисляем среднюю СКОРОСТЬ (Кбит/с) загрузки канала и общий ОБЪЕМ (Кбайт) скачанного пользователем, складываем КОЛ-ВО ЗАПРОСОВ от пользователя
# awk -v s="$s" '{pop[$1]+=$2; pop2[$1]+=$3}; END {for (cc in pop) if (pop[cc]>0) \
# {printf "%-20s %10.1f Mb\t %10.1f Kbit/s %10s hits\n", cc, pop[cc]/1048576, pop[cc]*8/(1024*s), pop2[cc]}}' _1 | sort -rnk6 | head -n 10 > _2
 awk -v s="$s" '{pop[$1]+=$2; pop2[$1]+=$3}; END {for (cc in pop) if (pop[cc]>0) \
 {printf "%-20s %10.1f Mb\t %10.1f Kbit/s %10s hits\n", cc, pop[cc]/1048576, pop[cc]*8/(1024*s), pop2[cc]}}' _1 | sort -rnk$kn | head -n 10 > _2
 clear
 echo -e "\nSeconds passed: $s" >> _2
 cat _2
 (( s++ ))	# s: Количество прошедший секунд с начала мониторинга, для расчета средней СКОРОСТИ загрузки канала
 sleep 1	# Время задержки в секундах
done
