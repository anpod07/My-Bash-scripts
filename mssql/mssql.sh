#!/usr/local/bin/bash
# ------------------------------------------------------------------- #
# Ищем в первой колонке csv-файла выпадающие ID, отличающиеся от ID+1 #
# ------------------------------------------------------------------- #
# Готовим CSV-файл для последующей обработки
sed '1d' $1 | recode -f CP1251..UTF-8 | tr -d "\"" > textf
tx="textf"
# Файл со значениями, разделенными новыми строками
mapfile -t arr < $tx
i=0; n1=0; n2=0
# recordID в первой строке
n1=$(cut -d ";" -f1 <<<${arr[0]})
#echo $n1
for i in "${!arr[@]}"; do
# echo "arr[i-1]: ${arr[(($i-1))]} i=$i"
 # recordID в текущей строке
 n2=$(cut -d ";" -f1 <<<${arr[i]})
 echo "n1=" $n1
# echo "n2=" $n2
 if [ $(($n2-$n1)) -ne 1 -a $n2 -ne $n1 ]; then
  # Несоответствие обнаружено. Выводим предыдущую строку
  echo "HOLE DETECTED!  " ${arr[(($i-1))]}
  echo "HOLE DETECTED!  " ${arr[(($i-1))]} >> result
 fi
 # recordID в предыдущей строке
 n1=$n2
# echo $i ${arr[i]} $n1
done
rm textf
