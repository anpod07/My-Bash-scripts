#!/usr/local/bin/bash
# Отправка письма с аттачем из командной строки с помощью "sendmail"
# Формируем Заголовок письма
addr="ank01"
to="To: $addr"
sj="Subject: Test attachment"
ct="Content-Type: text/html; charset=utf8"
fl=`cat file.html`
# Отправляем письмо
echo -e "$to\n$sj\n$ct\n$fl" | sendmail -t
