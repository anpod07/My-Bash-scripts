#!/usr/local/bin/bash
#------------------------------------------------#
# Выборка статистики посещений Интернет по людям #
#------------------------------------------------#
rxhit="TCP_HIT\|TCP_IMS_HIT\|TCP_MEM_HIT\|TCP_NEGATIVE_HIT\|TCP_REFRESH_HIT"
rxmiss="TCP_CLIENT_REFRESH_MISS\|TCP_MISS\|TCP_REFRESH_MISS\|TCP_SWAPFILE_MISS\|TCP_TUNNEL"
afile=/usr/local/squid/var/logs/access-old.log
zfile=/usr/local/squid/var/logs/access-old.log.0.0.gz
#zfile=/usr/local/squid/var/logs/access-old.log.0.29.gz
zfile7=/usr/local/squid/var/logs/access-old.log.0.[0-6].gz
zfile31=/usr/local/squid/var/logs/access-old.log.0.*.gz
cd /usr/home/ivan/online/online_best_stat
# Функция выбора временного интервала
funk1 ()
{
acl=$1		# _acl или _acle
while [ "$inpi" != "t" -a "$inpi" != "y" -a "$inpi" != "w" -a "$inpi" != "m" ]
do
 echo -n "Today (t), Yesterday (y), Week (w), Month (m): "
 read inpi
 case $inpi in
  "t" )
      funk2 "$afile" grep; return 1 ;;
  "y" )
      funk2 "$zfile" zgrep; return 1 ;;
  "w" )
      funk2 "$zfile7" zgrep; return 1 ;;
  "m" )
      funk2 "$zfile31" zgrep; return 1 ;;
  * ) echo "You enter some shit. Repeat" ;;
 esac
done
}
# Функция обработки файла access-old.log или access-old.log.0.*.gz
funk2 ()
{
dfile=$1	# afile или zfile, $2 - grep или zgrep
if [ "$acl" = "_acle" ]; then
 arrf=(`awk -F ";" '{print $1}' _acle`)
 i=0; :>_2
 while [ -n "${arrf[i]}" ]
 do
  $2 ${arrf[i]} $dfile >> _2
  ((i++))
 done
 dfile="_2"
fi
# Приводим access-old.log[.?.gz] к виду: IP ; URL ; SIZE
$2 "$rxhit\|$rxmiss" $dfile | awk '{if ($6=="CONNECT") {print $3 "/" $5 "///" $7}; if ($6!="CONNECT") {print $3 "/" $5 "/" $7}}' |\
awk -F/ '{print $1 ";" $2 ";" $5}' | awk -F ";" '{pop[$1 ";" $3] += $2}; END {for (cc in pop) {print cc ";" pop[cc]}}' > _1
# Выбрать один из вариантов:
# 1. Сталкиваем 2 файла по полю IP-адреса, форматируем, отсекаем все, что меньше 1 Мб
awk -F ";" -v acl="$acl" '{if (FILENAME == acl) {pop[$1] = $2 " " $1; next} \
if (FILENAME != acl && $3 > 1048576) {if (pop[$1] != "") {printf "%-40s\t %-70s\t %10.1f MB\n", pop[$1], $2, $3/1048576} \
else {printf "_NO_ACL %-32s\t %-70s\t %10.1f MB\n", $1, $2, $3/1048576}}}' $acl _1 | sort -k1.1,2 -k4rn > result
# 2. Сталкиваем 2 файла по полю IP-адреса, форматируем, не отсекаем ничего, объем - в байтах
##awk -F ";" -v acl="$acl" '{if (FILENAME == acl) {pop[$1] = $2 " " $1; next} \
##if (FILENAME != acl) {if (pop[$1] != "") {printf "%-40s\t %-70s\t %10.0f B\n", pop[$1], $2, $3} \
##else {printf "_NO_ACL %-32s\t %-70s\t %10.0f B\n", $1, $2, $3}}}' $acl _1 | sort -k1.1,2 -k4rn > result
rm _*
}
# -------------
# Старт скрипта
# -------------
# Список АКЛ-ов: группы (users_unlim, users_1000, ...), one-site users (squid.conf)
grep "^acl.*src.*255.255.255.255" /usr/local/etc/squid/squid.conf | awk '{print $4 ";" $2}' | sed -e 's/\/255.255.255.255//g' | sort -u > _acl
# меню выбора пользователей
while [ -z "$inp" ]             # выполнять цикл, пока $inp остается пустой (enter или пробел)
do
 echo "From all users (all);"
 echo "Read from 'acl.dat' (file);"
 echo -n "ACL or IP (regex-mask): "
 read inp
done
case $inp in
 "all" )
    funk1 _acl
    # Сортировка по размеру сайта
    sort -k4rn result > result_by_size
    # Сортировка по общей сумме трафика, потребленного пользователем
    awk '{pop[$1 " " $2] += $4}; END {for (cc in pop) {printf "%-40s\t %10.1f MB\n", cc, pop[cc]}}' result | sort -k3rn > result_by_users_total_size ;;
 "file" )
    arr=(`cat acl.dat`)
    i=0; :>_acle
    while [ -n "${arr[i]}" ]
    do
     if [ -n "`grep ${arr[i]} _acl | awk -F ";" '{print $1}'`" ]; then
      echo `grep ${arr[i]} _acl` >> _acle
     fi
     ((i++))
    done
    funk1 _acle ;;
 * )
    grep $inp _acl > _acle
    funk1 _acle ;;
esac
