#!/usr/local/bin/bash
#------------------------------------------------#
# Выборка статистики посещений Интернет по людям #
#------------------------------------------------#
rxhit="TCP_HIT\|TCP_IMS_HIT\|TCP_MEM_HIT\|TCP_NEGATIVE_HIT\|TCP_REFRESH_HIT"
rxmiss="TCP_CLIENT_REFRESH_MISS\|TCP_MISS\|TCP_REFRESH_MISS\|TCP_SWAPFILE_MISS\|TCP_TUNNEL"
afile=/var/log/squid/access-old.log
zfile=/var/log/squid/access-old.log.0.0.gz
zfile7=/var/log/squid/access-old.log.0.[0-6].gz
zfile31=/var/log/squid/access-old.log.0.*.gz
cd /root/scripts/online-stat-daily
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
   * ) echo "You entered some shit. Repeat" ;;
  esac
 done
}
# Функция обработки файла access-old.log или access-old.log.0.*.gz
funk2 ()
{
 dfile=$1	# afile или zfile, $2 - grep или zgrep
 if [ "$acl" = "_acle" ]; then
  # Преобразуем условие поиска для grep или zgrep в виде строки: "172.22.104.12\|172.22.104.42\|172.26.4.7"
  arrd=(`awk -F";" '{print $1}' _acle`)
  if [ "${#arrd[@]}" -gt 1 ]	# Если кол-во элементов массива > 1, тогда используем конструкцию вида: "172.22.104.12\|172.22.104.42\|172.26.4.7"
   then var1=`echo ${arrd[@]} | awk 'gsub(" ","\\\|") {print $0}'`
   else var1=${arrd[0]}
  fi
#  echo "arrd: ${arrd[@]}"				# debug check
#  echo "kol-vo: `echo "${#arrd[@]}"`"	# debug check
#  echo "var1: $var1, $2, $dfile"		# debug check
  $2 "$var1" $dfile > _2		# Выборка grep/zgrep ($2) по заданной маске ($var1) за выбранный интервал ($dfile)
  dfile="_2"
 fi
  # Приводим access-old.log[.?.gz] к виду: IP ; URL ; SIZE
  $2 "$rxhit\|$rxmiss" $dfile | awk '{if ($6=="CONNECT") {print $3 "/" $5 "///" $7}; if ($6!="CONNECT") {print $3 "/" $5 "/" $7}}' |\
  awk -F/ '{print $1 ";" $2 ";" $5}' | awk -F ";" '{pop[$1 ";" $3] += $2}; END {for (cc in pop) {print cc ";" pop[cc]}}' > _1
  # Выбрать один из вариантов:
  # 2. Сталкиваем 2 файла по полю IP-адреса, форматируем, не отсекаем ничего, объем - в байтах
  awk -F ";" -v acl="$acl" '{if (FILENAME == acl) {pop[$1] = $2 " " $1; next} \
  if (FILENAME != acl) {if (pop[$1] != "") {printf "%-40s\t %-70s\t %15.0f B\n", pop[$1], $2, $3} \
  else {printf "_NO_ACL %-32s\t %-70s\t %15.0f B\n", $1, $2, $3}}}' $acl _1 | iconv -c -f KOI8-R -t UTF-8 | sort -k1.1,2 -k4rn > result
 rm _*
}
funk3 ()
{
 # Сортировка по размеру сайта
 sort -k4rn result > result_by_size
 # Сортировка по общей сумме трафика, потребленного пользователем
 cut -f1,3 result | awk 'gsub(" B","", $0)' |\
 awk -F\t '{pop[$1] += $2}; END {for (cc in pop) {printf "%-40s\t %15.0f B\n", cc, pop[cc]}}' | sort -k3rn > result_by_users_total_size
}
# -------------
# Старт скрипта
# -------------
# Список АКЛ-ов: группы (users_unlim, users_1000, ...), one-site users (squid.conf)
grep "^acl.*src.*/32" /usr/local/etc/squid/squid.conf | awk '{print $4 ";" $2}' | sed -e 's/\/32//g' > _3
cat /usr/local/etc/squid/lists/users_* | tr -d "[:blank:]" | awk -F "/32#" '{print $1 ";" $2}' >> _3
sort -u _3 | iconv -c -f UTF-8 -t KOI8-R > _acl	# кодировка KOI8-R позволит правильно отработать форматированию строк в 'printf'
# меню выбора пользователей
while [ -z "$inp" ]		# выполнять цикл, пока $inp остается пустой (enter или пробел)
do
 echo "From all users (all);"
 echo "Read from 'acl.dat' (file);"
 echo -n "ACL or IP (regex-mask): "
 read inp
done
case $inp in
 "all" )
    funk1 _acl
    funk3 ;;
 "file" )
    arr=(`cat acl.dat`)
    i=0; :>_acle
    while [ -n "${arr[i]}" ]
    do
     if [ -n "`grep ${arr[i]} _3 | awk -F ";" '{print $1}'`" ]; then
      echo `grep ${arr[i]} _3` | iconv -c -f UTF-8 -t KOI8-R >> _acle
     fi
     ((i++))
    done
    funk1 _acle
    funk3 ;;
 * )
    grep $inp _3 | iconv -c -f UTF-8 -t KOI8-R > _acle
    funk1 _acle
    funk3 ;;
esac
