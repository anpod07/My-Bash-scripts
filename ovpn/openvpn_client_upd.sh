#!/usr/local/bin/bash
# ----------------------------------------- #
# Обновление БД ClamAV через OpenVPN-client #
# ----------------------------------------- #
cd /usr/home/prx/scripts/ovpn
openvpn vpngate_vpn594969837.opengw.net_udp_1195.ovpn 1> log.txt &
echo "Connecting to: vpn594969837.opengw.net ..."
sleep 5
i=0
while [ $i -lt 10 ]; do
 if [ -z "`grep 'Initialization Sequence Completed' log.txt`" ]
  then
   echo "Not connected..."
   sleep 5
   ((i++))
  else
   kll=`ps aux | grep -m1 "openvpn vpngate_vpn594969837.opengw.net_udp_1195.ovpn" | awk '{print $2}'`
   echo "kll = $kll"
#   echo "UPDATING..." && read inp && kill $kll
   echo "UPDATING..." && freshclam && kill $kll
   i=11
 fi
done

if [ $i -eq 10 ]; then
 openvpn vpngate_37.151.3.167_udp_1195.ovpn 1> log.txt &
 echo "Connecting to: 37.151.3.167 ..."
 sleep 5
 i=0
 while [ $i -lt 10 ]; do
  if [ -z "`grep 'Initialization Sequence Completed' log.txt`" ]
   then
    echo "Not connected..."
    sleep 5
    ((i++))
   else
    kll=`ps aux | grep -m1 "openvpn vpngate_37.151.3.167_udp_1195.ovpn" | awk '{print $2}'`
    echo "kll = $kll"
#    echo "UPDATING..." && read inp && kill $kll
    echo "UPDATING..." && freshclam && kill $kll
    i=11
  fi
 done
fi
