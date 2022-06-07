#!/usr/local/bin/bash
# ========================================================== #
# Сбор интернет-статистики, используя файлы /report/*.log
# ========================================================== #
# Список файлов: online-stat-month.sh, online-stat-month.sql
#		 из /report/*.log (выборочно)
# ========================================================== #
fullpath="/usr/home/ivan/online/online_stat_month"
src="$fullpath/online-stat-month.sql"
result="$fullpath/result.dat"
cd $fullpath
:>$result
# Берем актуальный список пользователей из БД, имеющих ACL
sqlplus u44700@proj/... <<EOF
 SET LINESIZE 140
 SET PAGESIZE 1500
 spool $result
 @$src
 spool off
 disconnect
 exit
EOF
# отбрасываем первые 4 строки, потом последние 4 строки, убираем лишние пробелы
sed -e '1,4d' $result | sed -e :a -e '$d;N;2,4ba' -e 'P;D' | awk -F ";" 'gsub("      *","") {print $0}' | grep -v "^;" > all
# выборка из log-ов записей для конкретного отдела (по маске), закоментарить строку, если нужны все записи
#grep -h '^ГЛ_БУХ\|^ГЛБУХ\|^ГБ_\|^БМР_\|^ЦРБ_' /usr/local/etc/squid/report/*2020.log > /usr/home/ivan/online/online_stat_month/res_2020.log
grep -h 'ООИАП_ЛАВРИК_Д_А' /usr/local/etc/squid/report/*2021.log > /usr/home/ivan/online/online_stat_month/res_2021.log
# перекодируем, объединяем и суммируем все месячные лог-файлы в один
awk -F ";" '{pop[$1";"$2]+=$3}; END {for (cc in pop) {print cc ";" pop[cc]}}' *.log | sort -t ";" -k3rn > log
# заменяем ACL на ФИО; если нет ФИО - пишем ACL (размер в байтах)
#awk -F ";" '{{if (FILENAME == "all") {pop[$6] = $1 ";" $2 ";" $3 ";" $4 ";" $5; next}} \
#             {if (FILENAME != "all") {if (pop[$1] != "") {print pop[$1] ";" $2 ";" $3} \
#				       else {print $1 ";" $2 ";" $3}}}}' all log > result
# заменяем ACL на ФИО; если нет ФИО - пишем ACL (размер в мега-байтах), не отсекаем ничего
#awk -F ";" '{{if (FILENAME == "all") {pop[$6] = $1 ";" $2 ";" $3 ";" $4 ";" $5; next}} \
#             {if (FILENAME != "all") {if (pop[$1] != "") {print pop[$1] ";" $2 ";" $3/1048576 " MB"} \
#            			      else {print $1 ";" $2 ";" $3/1048576 " MB"}}}}' all log > result
# заменяем ACL на ФИО; если нет ФИО - пишем ACL (размер в мега-байтах), отсекаем все, что меньше 1 Мб
awk -F ";" '{{if (FILENAME == "all") {pop[$6] = $1 ";" $2 ";" $3 ";" $4 ";" $5; next}} \
             {if (FILENAME != "all" && $3 > 1048576) {if (pop[$1] != "") {printf "%s;%s;%.1f\n", pop[$1], $2, $3/1048576} \
						      else {printf "%s;%s;%.1f\n", $1, $2, $3/1048576}}}}' all log > result
# сортируем по человеку и объему
sort -t ";" -k1.1,2 -k7rn result > result_otdel
# берем только top-20-сайтов по объему на каждого человека
#i=0; result_otdel_20
#arr=(`awk -F ";" '{print $1";"$2";"$3}' result_otdel | sort -u`)
#while [ -n "${arr[i]}" ]; do
# grep "${arr[i]}" result_otdel | head -n 20 >> result_otdel_20
# ((i++))
#done
rm $result log all
