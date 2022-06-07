#!/usr/local/bin/bash
# clear in /etc/mail/aliases
fl="aliases_test"
a="akulenko"

# Examples
#sed -e "s/ !${acl[i]}//"
#sed -e "/[[:space:]]${arr[i]}.nkmz/d"

# worked!!!
#sed -e "s/, $a//" -e "/[[:space:]]$a$/d" -e "s/$a, //" $fl > zzz
# worked NEW!!!
#sed -e "s/$a, //" -e "s/, $a$//" -e "/[\t]$a$/d" $fl > zzz
# worked!!!
#sed -E "/:[[:blank:]]+$a$/d" $fl > zzz
# all together WORKED
#sed -e "s/ $a, //" -e "s/, $a$//" $fl | sed -E "/:[[:blank:]]+$a$/d" | sed -E "s/:[[:blank:]]+$a, /:`echo -e "\t"`/" > zzz
# all together WORKED with one TAB
#sed -e "s/ $a, //" -e "s/, $a$//" -e "s/`echo -e "\t"`$a, /`echo -e "\t"`/" -e "/`echo -e "\t"`$a$/d" $fl > zzz

# Final worked!!!
#sed -E "s/:[[:blank:]]+$a, /:`echo -e "\t"`/" $fl | sed -e "s/ $a, //" -e "s/, $a$//" | sed -E "/:[[:blank:]]+$a$/d" > zzz
# Final worked on FreeBSD 12!!!
sed -E "s/:[[:blank:]]+$a, /:\t/" $fl | sed -e "s/ $a, //" -e "s/, $a$//" | sed -E "/:[[:blank:]]+$a$/d" > zzz

#sed "s/34/\t/" $fl
