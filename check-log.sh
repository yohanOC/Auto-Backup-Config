#!/bin/bash
trap break INT
script_location="/root/Auto-Backup"
log_location="/root/Auto-Backup/devices-log.txt"
sed -i '/SYS-5-CONFIG_I\|VSHD-5-VSHD_SYSLOG_CONFIG_I/!d' $log_location
current="$(cat $script_location/current)"
checking="$(cat /root/Auto-Backup/devices-log.txt | grep -i "SYS-5-CONFIG_I\|VSHD-5-VSHD_SYSLOG_CONFIG_I" | wc -l)"
>$script_location/failure_report
if [ $checking -gt $current ]
then
        calculate=$((checking-current))
		tail -$calculate $log_location | awk '{for (i=1; i<=NF; i++) if ($i=="by") print $4, $(i+1)}' > $script_location/tempip
		filter="$(cat $script_location/tempip | sort | uniq)"
		counter="$(cat $script_location/tempip | sort | uniq -c | sed -e 's/^[[:space:]]*//g' | sed -e 's/[[:space:]]*$//g')"
		while read -r ip user 
		do 
			if ping -q -W 1 -c2 "$ip" &>/dev/null; 
			then 
				precheck="$(cat $script_location/deviceslist | grep -w $ip | wc -l)"
				if [ $precheck -lt 1 ]
				then
					newhost="$(snmpwalk -v2c -c dokternetwork $ip sysName.0 | awk -F'STRING: *' '{print $2}' | cut -d "." -f1)"
					sleep 2
					pat="$(echo $newhost | cut -d "-" -f1)"
					recheck="$(cat $script_location/deviceslist | grep -i $pat | wc -l)"
					if [ $recheck -lt 1 ]
					then
						sed -i "\$a\\$newhost $ip" $script_location/deviceslist
					else
						last="$(cat deviceslist | grep -i $pat | tail -1 | cut -d " " -f1)"
						sed -i "/$last/a\\$newhost $ip" $script_location/deviceslist
					fi
				fi
				hostname="$(cat $script_location/deviceslist | grep -w $ip | cut -d " " -f1)"
				site="$(echo $hostname | cut -d "-" -f1)"
				path="$(find / -type d -name "$site")"
				expect $script_location/backup_script.exp $ip > $path/$hostname
				if [ $? -eq 0 ]
				then
					hostname="$(cat $script_location/deviceslist | grep -w $ip | cut -d " " -f1)"
					cd $path
					git add $hostname
					git commit -m "Update configuration by $user" $hostname 
					git push -f
					cd $script_location
					balance="$(echo "$counter" | grep -w $ip | cut -d " " -f1)"	
					current="$(cat $script_location/current)"
					addcounter=$((balance+current))
					echo $addcounter > current
				else
					cd $path
					rm -f $hostname
					date="$(date)"
					echo "$date $hostname connection failure during backup process please check" >> $script_location/failure_report
					cd $script_location
					balance="$(echo "$counter" | grep -w $ip | cut -d " " -f1)"	
					current="$(cat $script_location/current)"
					addcounter=$((balance+current))
					echo $addcounter > current
				fi	
			fi
		sleep 2
		done <<<"$filter"
fi
trap - INT
