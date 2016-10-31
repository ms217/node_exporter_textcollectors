#!/bin/bash
#
#Author/Copyright: Michael Seevogel (c) 2016
#License: GNU GPL v3
#
#Brief Description:
#
#This script will do a reverse lookup of your configured IPs at Return Path's Senderscore reputation system
#These results will help you to visualise the reputation in Prometheus/Grafana over time.
#Kinda handy if you want to monitor the impact of your mailflow when you send mails to the big mailproviders such as Hotmail/Outlook, Yahoo or Comcast and couple of others.
#
#Set this script up via cron. You may let the cronjob run something between every 10-60 minutes.

#This script needs the ip command and you may have to define the PATH variable or alternatively the IP_CMD variable.
#That's up to you and what you prefer...

source /opt/node_exporter_textfile/env.sh
 
IP_CMD=`which ip`  

#get all non-private ip adresses that have been configured on this system
for get_IPS in `$IP_CMD -o addr | awk '!/^[0-9]*: ?lo|link\/ether/ {gsub("/", " "); print $4}' | grep -Eo "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | egrep -v "(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|(192.168|172.16)\.[0-9]{1,3}\.[0-9]{1,3})"`
do
        IPS+=$(echo $get_IPS$'\t')

done

#reverse ip to in-addr.arpa scheme
for reverse in ${IPS[@]}
do
	REVERSED+=$(echo $reverse | awk -F'.' '{print $4"."$3"."$2"."$1" " }')
done


#do the lookup
for lookup in ${REVERSED[@]}
do
	GETSCORE=$(nslookup $lookup.score.senderscore.com | egrep -o "127.0.4.[0-9]{1,3}" | awk -F'.' ' { print $4 } ')
	if [[ "$GETSCORE" -lt 1 ]] || [[ "$GETSCORE" -eq "" ]]
	then
		#In case that this if statement is being triggered a score of 0 could mean the following:
		# 1. Return-Path's Senderscore hasn't recently seen enough mails from your sending IPs
		#    The sending IP(s) is/are "cold". Warm up your IPs by sending more *good* emails to hotmail/gmail/comcast/yahoo/(you name it...) users, so that your IPs get listed at Return Path's Senderscore.
		# 2. Your IPs were recently sending spam and so that your reputation-score has dropped heavily
		#    A score between  0 - 30 is actually very bad and your mails will most likely get rejected by the receiving MTA
		#    A score between 31 - 60 is still bad. Your mails may still get rejected but the chance increases slightly that your mails may at least arrive the junk folder of your recipients
		#    A score between 61 - 80 could still mean that your mails may end in the junk folder of your recipients mailbox, but your mails should be in most cases accepted by the receiving MTA.
		#    A score between 81 - 100 is what you should generally aim for.

		GETSCORE=0
	fi
	SCORE=$GETSCORE
	ARRAY+=$(echo -ne $lookup | awk -F'.' '{print $4"."$3"."$2"."$1",""'$SCORE'"";"}')
done


IFS=';'

#flush the previous results
echo -n "" > $NODE_TEXTFILE_DIR/senderscore.prom

for IP_SCORE in ${ARRAY[@]}
do

	IP=$(echo $IP_SCORE | cut -d',' -f1)
	SCORE=$(echo $IP_SCORE | cut -d',' -f2)
	echo "node_senderscore{ip=\"$IP\"} $SCORE" >> $NODE_TEXTFILE_DIR/senderscore.prom


done



