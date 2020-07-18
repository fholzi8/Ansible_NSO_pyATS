#!/bin/sh

tail -Fn0 /tcpdump/log/ace/ace.log | while read line ; do
#	echo "$line" | grep "Health probe failed for server 172.16.1.61 on port 443, connection reset by"
	echo "$line" | grep "on port 443, connectivity error: server open timeout (no SYN ACK)"
		if [ $? = 0 ]
		then
		/opt/scripts/test-scripts/ciscotac.py -c /opt/scripts/test-scripts/command-list.txt
		echo "Yeah: $line"
		sleep 300
                /opt/scripts/test-scripts/ciscotac.py -c /opt/scripts/test-scripts/command-list.txt
		mail -s "CiscoTAC 4 ACE" "cisco@company.com" << EOF
SSL-Distruption on Loadbalancer occurred:

$line

Please look for the output at /tcpdump/hostname... and send it to support@bechtle.com

EOF
		fi
	done
