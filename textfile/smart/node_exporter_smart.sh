#!/bin/bash
#Author/Copyright: Michael Seevogel (c) 2016
#License: GNU GPL v3
#
#Brief Description:
#
#This script will get the SMART raw values of your existing hard-drives and put them into a .prom file that can be later read by the textfile plugin of Prometheus node_exporter.

source /opt/node_exporter_textfile/env.sh

declare -a DRIVES
declare -a RAW_VALUE

#find out which hard-drives do exist on this system...
for GET_DRIVE in $(cat /proc/partitions | awk ' { print $4 } ' | egrep "(s|h).*[a-z]$")
do
	DRIVES+="/dev/$GET_DRIVE "
done

#get the raw values of each drive
for DRIVE in ${DRIVES[*]}
do
        RAW_VALUE+=$(smartctl -A $DRIVE | awk '/;/{f=1;};f{print;};/ID#/{f=1;}' | sed '$d' | awk ' { print "'$DRIVE'"","$2","$10"; " } ')
done


#flush the previous results
echo -n "" > $NODE_TEXTFILE_DIR/smart.prom


#assemble everything...
for VALUES in ${RAW_VALUE[@]}
do
	IFS=';'
	echo $VALUES
	DRIVE=$(echo $VALUES | cut -d',' -f1)
	VALUE_NAME=$(echo $VALUES | awk -F',' ' { print $2 } ')
	VALUE=$(echo $VALUES | awk -F',' ' { print $3 } ')
	echo "node_smart{drive=\"$DRIVE\",name=\"$VALUE_NAME\"} $VALUE" >> $NODE_TEXTFILE_DIR/smart.prom

done

unset IFS
