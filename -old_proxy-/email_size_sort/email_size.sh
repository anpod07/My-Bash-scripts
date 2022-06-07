#!/usr/local/bin/bash
#----------------------------------#
# считает объем отправленной почты #
#----------------------------------#
dirl="/var/log/Daily"		# место хранения почтовых логов
#sizechk=100			# не писать в отчет записи < $sizechk мегабайт
sizechk=10			# не писать в отчет записи < $sizechk мегабайт
datt=`date +%d-%m-%Y`		# сегодняшняя дата
#daty=`date -v -1d +%d-%m-%Y`	# вчерашняя дата
:>result			# очистка файла отчета

funcany ()			# from @nkmz.donetsk.ua to any
{
i=0
arrls=($1)
while [ -n "${arrls[i]}" ]	# обрабатываем все записи в массиве имен
do
 awk -F ";" '{if ($2 ~ "@nkmz.donetsk.ua") {pop[$2" --> "$3]+=$4; pop1[$2" --> "$3]+=1}} \
 END {for (i in pop) if (pop[i]/1048576 > sizchk) {printf "%10s %-70s\t %10.1f Mb %10s pisem\n", iddat, i, pop[i]/1048576, pop1[i]}}' \
 sizchk=$sizechk iddat=${arrls[i]} $dirl/${arrls[i]}.log | sort -rnk5 >> result
 echo "---" >> result
 (( i++ ))
done
}

funcnkmz ()			# from @nkmz.donetsk.ua to @nkmz.donetsk.ua
{
i=0
arrls=($1)
while [ -n "${arrls[i]}" ]	# обрабатываем все записи в массиве имен
do
 awk -F ";" '{if ($2 ~ "@nkmz.donetsk.ua" && $3 ~ "@nkmz.donetsk.ua") {pop[$2" --> "$3]+=$4; pop1[$2" --> "$3]+=1}} \
 END {for (i in pop) if (pop[i]/1048576 > sizchk) {printf "%10s %-70s\t %10.1f Mb %10s pisem\n", iddat, i, pop[i]/1048576, pop1[i]}}' \
 sizchk=$sizechk iddat=${arrls[i]} $dirl/${arrls[i]}.log | sort -rnk5 >> result
 echo "---" >> result
 (( i++ ))
done
}

funcchoose ()
{
 echo "Press (1) for <from @nkmz.donetsk.ua to any>"
 echo "Press (2) for <from @nkmz.donetsk.ua to @nkmz.donetsk.ua>"
 echo -n ": "
 read inpch
 case $inpch in
  1 ) funcany "$r4" ;;
  2 ) funcnkmz "$r4" ;;
  * ) echo "Entered some shit. Abort."; exit 1 ;;
 esac
}

funcwork ()			# создание списка имен log-файлов для обработки
{
 i=$1
 j=$2
 while [ $i -le $j ]
 do
  r1="date -v -"
  r2="d +%d-%m-%Y"
  r3=`$r1$i$r2`
  r4=`echo $r4" "$r3`
  (( i++ ))
 done
# funcany "$r4"
 funcchoose
}

# start fo script
echo -n "Choose period: Today (1) or Yesterday and later (2): "
read instr
case "$instr" in
 1 )
   echo "Entered 1. Today stat"
   # создание сегодняшнего log-файла
   cat /var/log/maillog | grep "to=\|from=<" | grep -v "nkmz sendmail" | awk '{print $6 "\t"$1 "\t" $2 "\t" $3 "\t" $7 "\t" $8}' | sort -t: -n | \
   grep -B 1 "to=" | grep -v "\-\-" | awk '{ if (match($0,"from=<")) {S1=$1 " " $2 " " $3 " " $4 " " $5 " "$6; getline; S2=$5; print S1, S2}}' | \
   awk -f stat3.awk > $datt.log
   dirl="."
   funcwork 0 0
   rm $datt.log
   echo Done 1!
   ;;
 2 )
   echo -n "Enter number of days for getting stat (Yesterday = 1, and so on...): "
   read dayn			# количество дней (log-файлов) для обработки
   regul='^[0-9]+$'		# проверка на ввод числа
   if ! [[ $dayn != 0* && $dayn =~ $regul ]]	# если $dayn не начинается с нуля И $dayn содержит только цифры
    then
     echo "Error: null or not a number."
     exit 1
   fi
   if [ $dayn -gt 30 ]
    then
     echo -n "Entered $dayn > 30 days. Want procceed? (y/n) "
     read daypr
     case $daypr in
      "y"|"Y" ) ;;
             *) exit ;;
     esac
   fi
   funcwork 1 $dayn
   echo Done 2!
   ;;
 * )
   echo "Entered some shit. Abort."
   exit 1
   ;;
esac
