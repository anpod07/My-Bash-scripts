#!/usr/local/bin/bash
# Отправка письма с аттачем из командной строки с помощью "mail"
echo 'Test message' | uuencode ./file.html TestFile.html | mail -s "Test html-attachment" ank01
