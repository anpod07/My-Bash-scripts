#!/usr/local/bin/bash
#=================================#
# Список пользователей для Zimbra #
#=================================#

# В качестве MTA: mail.nkmz.donetsk.ua. Zimbra может работать с несколькими разными MTA, например mail.nkmz.com
mta="mail.nkmz.donetsk.ua"
suf="@nkmz.donetsk.ua"
# pr_raboty=$2=1, email=$11, fam=$3, name=$4, midname=$5, dep=$8, prof=$9
# pr_raboty=$2="", email=$11, fam=$12, dep=$13
fl=/home/prx/scripts/sqlplus_all/all

# Получаем файл с нужными полями, без пароля
awk -F ";_;" '{if (length($2)<1 && length($11)>1) {print $11suf";;;"$12,"-",$13";"mta} \
			   else {if ($2~"1" && length($11)>1) {print $11suf";"$3";"$4";"$3,$4,$5,"-",$8,"-",$9";"mta}} \
			  }' mta=$mta suf=$suf $fl > _1

# Генерим файл с паролями по количеству строк в предыдущем файле
arr=(`awk -F ";" '{print $1}' _1`)
i=0; :>_2
for i in "${arr[@]}"; do
 echo "$i;$(echo `dd if=/dev/random bs=10 count=1 2>/dev/null | openssl base64 | grep -o '[[:alnum:]]' | head -n 6 | tr -d '\n'`)" >> _2
done

# Объединяем файлы в виде списка
#awk -F ";" '{{if (FILENAME == "_1") {pop[$1] = $0; next}} \
#             {if (FILENAME != "_1") {print pop[$1] ";" $2}}}' _1 _2 |\
#             tr -s "," " " | awk -F ";" '{print $1";"$6";"$2";"$3";"$4";"$5}' | tr -s ";" "," > result

# Объединяем файлы в виде строки
awk -F ";" '{{if (FILENAME == "_1") {pop[$1] = $0; next}} \
             {if (FILENAME != "_1") {print pop[$1] ";" $2}}}' _1 _2 |\
             tr -s "," " " | awk -F ";" '{printf "%s;%s;%s;%s;%s;%s;", $1, $6, $2, $3, $4, $5}' | tr -s ";" "," > result
rm _1 _2
