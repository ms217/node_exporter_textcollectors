#!/bin/bash

#Global Variables
#******************************************************************************************************************

#Adjust this var so that it matches what you've defined through --collector.textfile.directory
NODE_TEXTFILE_DIR=/var/lib/prometheus/metrics
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"


#LSI Controller
###############
#If you have a LSI Controller and you don't have the MegaCli binary in path, then you should uncomment
#this var and adjust the path to your MegaCli64 binary accordingly!
#MEGA_CLI_BIN=/opt/MegaRAID/MegaCli/MegaCli64

#In case that your Adapter Id is not a0, then you should adjust this var to match your environment accordingly
LSI_ADAPTER_ID=a0
LSI_ARRAY=/dev/sda



#Global Functions
#******************************************************************************************************************

function CommandExists() {
	type "$1" &> /dev/null ;
}



