#!/bin/sh
#fetch https://database.clamav.net/daily.cvd
#curl https://database.clamav.net/daily.cvd
lynx -source "https://database.clamav.net/bytecode.cvd" > 123.cvd
#lynx https://database.clamav.net/bytecode.cvd
