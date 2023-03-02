#!/bin/sh
# D-Link ports checker

export TERM=xterm
mypath="/home/zabbix"
rm -rf $mypath/out.txt

# check installed packets
#if [ -f /usr/bin/dialog ]; then
#	echo "All packets installed!">/dev/null;
#else
#    echo "Please install dialog!\033[0m"; 
#    exit;
#fi

input=$1

# maximum numbers of ports

ports="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28"

# snmp community name
community="public"

# your autorization password to access for client, if you using script in terminal and if this needed
auth_passw="123456"

passwd=$auth_passw # if autorization not needed, uncomment this string
#passwd=$(dialog --stdout --title "Password" --colors --insecure --passwordbox "Enter password:"  \10 35) # if autorization not needed, comment this string
now_time=$(date '+%c')

if [ "$passwd" = "$auth_passw" ]; then

	# check host for ping. If host unreachable then exit
	ping -c1 $input>/dev/null && echo "ok">/dev/null || exit
	echo "IP:	" $input>>$mypath/out.txt
	
	# check for model name
	model=$(snmpwalk -v2c -c  $community $input .1.3.6.1.2.1.1.1.0 | awk {'print $4, $5, $6, $7'})
	
	# check snmp system name
	snmpname=$(snmpwalk -v 2c -c $community $input .1.3.6.1.2.1.1.5.0 | awk {'print $4'})
	
	# check for uptime
	uptime=$(snmpwalk -v 2c -c $community $input 1.3.6.1.2.1.1.3 | awk {'print $5, $6, $7'})
	echo "Модель:	" $model>>$mypath/out.txt
	echo "Имя:	" $snmpname>>$mypath/out.txt
	echo "Аптайм:" $uptime>>$mypath/out.txt
	echo "------------------------------------">>/home/zabbix/out.txt
	echo "Порт    Активность    Состояние  Ош.">>/home/zabbix/out.txt
	echo "------------------------------------">>/home/zabbix/out.txt
	
	# numbers checked ports 1 2 3 4 5 and etc.
	for number in $ports
		do
		# check host access
		snmpwalk -v 2c -c $community  $input  .1.3.6.1.2.1.31.1.1.1.3.$number | grep "OID">/dev/null
			if [ $? -eq 0 ]; then 
				 echo "inactive">/dev/null
			else
				# check ports for crc errors
				crc_port=$(snmpwalk -v 2c -c $community  $input  .1.3.6.1.2.1.10.7.2.1.3.$number | awk {'print $4'})
				
				# check ports status up or down
				port_up_down=$(snmpwalk -v 2c -c $community $input 1.3.6.1.2.1.2.2.1.8.$number | awk {'print $4'})
				if [ "$port_up_down" = "1" ]; then
					status="[■]"
				else
					status="[ ]"
				fi
				
				# check ports admininstrative status
	            status_port=$(snmpwalk -v 2c -c $community  $input  1.3.6.1.2.1.2.2.1.7.$number | awk {'print $4'})
				if [ "$status_port" = "2" ]; then
					status="[X]"
                fi

				# check ports for broadcast traffic and output to file
				snmpwalk -v 2c -c $community  $input  .1.3.6.1.2.1.31.1.1.1.3.$number | grep "Counter32: 0">/dev/null && \
				 echo $number "	Не использ.	" $status "	" $crc_port "	" >>$mypath/out.txt || \
 				 echo $number "	Использ.	" $status "	" $crc_port "	" >>$mypath/out.txt
			fi
		done
fi
# if you using script in terminal uncomment next string
#cat $mypath/out.txt
