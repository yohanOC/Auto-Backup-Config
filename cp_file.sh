#!/bin/bash
syslogfile="$(cat /var/log/network-log/devices-log.txt | grep -i SYS-5-CONFIG_I | wc -l)"
adminfile="$(cat /root/Auto-Backup/devices-log.txt | grep -i SYS-5-CONFIG_I | wc -l)"
if [ $syslogfile -gt $adminfile ]
then
        cp -f /var/log/network-log/devices-log.txt /root/Auto-Backup/devices-log.txt
fi
