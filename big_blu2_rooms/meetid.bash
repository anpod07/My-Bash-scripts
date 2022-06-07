#!/usr/local/bin/bash
#
fl="/usr/local/www/default/docs/bb.html"
flbb="bbb-web.log"
cd /home/prx/scripts/big_blu2_rooms
# downloading BigBlu2 XML-file and splitting it on Meetings
cd ./mess
rm 0*
curl -s http://bigblu2.nkmz.donetsk.ua/bigbluebutton/api/getMeetings?checksum=66db48a287b9bad1517bae7e5710349e7b78439c |\
split -p "^<meeting>" -d -a2 - 0
#cat ../meetid.orig | split -p "^<meeting>" -d -a2 - 0
cd ..
# generating html-file
echo "<head>" > $fl; echo "<meta charset="utf-8">" >> $fl; echo "</head>" >> $fl; echo "<body>" >> $fl
# room=file array
arr=(`ls ./mess`)
i=1 # Skiping first file, no <meeting> in it
while [ -n "${arr[i]}" ]; do
 if [ -n "`grep '^<running>true' ./mess/${arr[i]}`" ]; then 
  # link array, need ${arl[0]}
  arl=(`grep '^<meetingID>' ./mess/${arr[i]} | awk -F ">" '{print $2}' | awk -F "<" '{print $1}'`)
#  echo "arl=${arl[0]}"
  # room-name array, need ${arn[0]}
  arn=(`grep '^<meetingName>' ./mess/${arr[i]} | awk -F ">" '{print $2}' | awk -F "<" '{print $1}' | tr " " "_"`)
#  echo "arn=${arn[0]}"
  # creator-name + role array, need ${arc[0]}
  arc=(`grep -A1 '^<fullName>' ./mess/${arr[i]} | awk '{if (match($0,"^<fullName>")) {s1=$0; getline; s2=$0; print s1 ";" s2}}' |\
  grep "MODERATOR" | awk -F ">" '{print $2}' | awk -F "<" '{print $1}' | tr " " "_"`)
#  echo "arc=${arc[0]}"
  url=`grep "meetingID:\[${arl[0]}\]" $flbb | head -n1 | awk -F "logoutURL:" '{print $2}' | awk -F "logout" '{print $1}' | tr -d "["`
#  echo "url=$url"
  # generating url list in html-file
  echo "<li><a href=\"$url\">${arn[0]} ::: <b>${arc[0]}</b></li>" >> $fl
 fi
 ((i++))
done
echo "</body>" >> $fl
