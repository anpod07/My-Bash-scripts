#!/bin/sh
# ������������� reboot ������� � ������������ iscsi �� �������
if [ -z "`ls /dev/da* | grep da3s1d`" ]
 then
  echo "da3s1d not found. Mounting..."
  iscontrol -c /etc/iscsi.conf -n officeiscsi
  sleep 5
  mount /dev/da3s1d /maillog
 else
  echo "da3s1d found"
fi
