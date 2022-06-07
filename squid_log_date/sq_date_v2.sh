#!/usr/local/bin/bash
# -------------------------------------------------------- #
# выбрать из squid-лога строки за указанный период времени #
# -------------------------------------------------------- #
#fl="access.log"
fl="access-old.log"
fr="result"
# определяем дату начала и конца временного отрезка
#dt=`date -j -f "%d-%b-%Y-%T" "6-июня-2020-13:32:00" "+%d-%m-%Y-%T"`; dtb=`date -j -f "%d-%m-%Y-%T" $dt "+%s"`
dt=`date -j -f "%d-%b-%Y-%T" "18-июня-2020-11:30:00" "+%d-%m-%Y-%T"`; dtb=`date -j -f "%d-%m-%Y-%T" $dt "+%s"`
#echo $dtb
#dt=`date -j -f "%d-%b-%Y-%T" "6-июня-2020-13:35:00" "+%d-%m-%Y-%T"`; dte=`date -j -f "%d-%m-%Y-%T" $dt "+%s"`
dt=`date -j -f "%d-%b-%Y-%T" "18-июня-2020-11:45:00" "+%d-%m-%Y-%T"`; dte=`date -j -f "%d-%m-%Y-%T" $dt "+%s"`
#echo $dte
# определяем номер строки начала временного отрезка. Если дата не обнаружена - отнимаем 1 секунду
y=""
while [ -z "$y" ]; do
 sedb=`grep -n ^$dtb $fl | head -n1 | awk -F: '{print $1}'`
 #echo "dtb: $dtb"; echo "sedb: $sedb"
 if [ -n "$sedb" ]; then y="y"; fi
 ((dtb--))
done
# определяем номер строки конца временного отрезка. Если дата не обнаружена - прибавляем 1 секунду
y=""
while [ -z "$y" ]; do
 sede=`grep -n ^$dte $fl | head -n1 | awk -F: '{print $1}'`
 #echo "dte: $dte"; echo "sede: $sede"
 if [ -n "$sede" ]; then y="y"; fi
 ((dte++))
done
# отображаем строки за указанный интервал времени
sed -n ${sedb},${sede}p $fl > $fr
# переводим первый столбец squid-лога из Timestamp в нормальную дату+время (время работы скрипта зависит от размера полученного файла)
echo "Размер полученного файла: "`ls -l $fr | awk '{print $5}'`
echo -n "Переформатировать дату в полученном файле? (y/n)"; read i
if [ "$i" == "y" -o "$i" == "Y" ]
 then
  awk -F "." '{print $0, system("date -r " $1 " +%Y-%b-%d-%T")}' $fr | awk '{print $11,$2,$3,$4,$5,$6,$7,$8,$9,$10}' | grep -v '^ ' > $fr.new
 else echo "Оставлено все как есть."
fi
