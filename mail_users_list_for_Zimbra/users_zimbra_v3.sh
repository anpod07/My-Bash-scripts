#!/usr/local/bin/bash
#=================================#
# Список пользователей для Zimbra #
#=================================#

# В качестве MTA: mail.nkmz.donetsk.ua. Zimbra может работать с несколькими разными MTA, например mail.nkmz.com
suf="@nkmz.donetsk.ua"
fl=/home/prx/scripts/sqlplus_all/all
# pr_raboty=$2=1, email=$11, fam=$3, name=$4, midname=$5, dep=$8, prof=$9
# pr_raboty=$2="", email=$11, fam=$12, dep=$13

awk -F ";_;" '{cmd="echo `dd if=/dev/random bs=10 count=1 2>/dev/null | openssl base64 | tr -cd [:alnum:] | cut -c1-6`"; \
			   cmd | getline res; close (cmd); \
			   if (length($2)<1 && length($11)>1) \
			    {print "createAccount",$11suf,res,"givenName",sq sq,"sn",sq sq,"initials",sq sq,\
			     "displayName",sq$12sq,"description",sw$12,"-",$13sw} \
			   else {if ($2~"1" && length($11)>1) \
			    {print "createAccount",$11suf,res,"givenName",sq$4sq,"sn",sq$3sq,"initials",sq$5sq,\
			     "displayName",sq$3,$4sq,"description",sw$3,$4,$5,"-",$8,"-",$9sw}} \
			  }' suf=$suf sq="'" sw='"' $fl > result
