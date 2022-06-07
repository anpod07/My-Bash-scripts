#!/bin/sh
cd /var/log
zgrep "Stats:" qpopper.0.gz | awk '{print $7,$12,$13}' | sort -u | mail -s "TLS Stats" root
