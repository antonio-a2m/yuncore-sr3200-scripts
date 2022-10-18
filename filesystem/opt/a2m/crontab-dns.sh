#!/bin/ash
# 
# The first time this script is executed, just triggers the
# tcpdump process that captures all traffic passing
# through this router on port 53 (DNS traffic)
# From the 2nd time on, this scripts restarts the tcpdump process
# and formats the captured data into a csv file
# This script is meant to be executed by a crontab every 5 mins
# in order to keep file sizes manageable
# 0-59/5* * * * * /opt/a2m/crontab-dns.sh 
# Needs tcpdump installed

#
# Antonio Gonzalez aggarcia@gmail.com
# Oct 2020, the year of covid

DATE=$(/bin/date +"%Y_%m_%d_%H_%M_%S")
PREFIXTRAF=a2m-dns-traffic
LIVEFILE=/tmp/$PREFIXTRAF.log
TMPFILE=/tmp/dns-traffic-data-$DATE.txt
OUTFILE=/tmp/dns-traffic-data-$DATE.csv
PUBLICIP=$(curl ifconfig.me)
# I mean to ignore the traffic comming from device connected in port 5
MAC_CM=$(swconfig dev switch0 get arl_table|grep 'Port 5'|cut -d' ' -f4)

#if there is a process running, kill it and dump the files
ISRUNNING=$(ps |grep tcpdump |grep -v grep|wc -l)
if [ $ISRUNNING -gt 0 ]; then
    PID=$(ps |grep tcpdump |grep -v grep|tr -s ' '|cut -f2 -d' ')
    if [ $PID = "root" ]; then
        PID=$(ps |grep tcpdump |grep -v grep|tr -s ' '|cut -f1 -d' ')
    fi
    kill $PID
    echo "running alredy, killing process $PID"

    #dump the file
    #echo "moving live file mv $LIVEFILE $TMPFILE"
    mv $LIVEFILE $TMPFILE
    #restart immediately
    #echo restarting process
    tcpdump -e -Q in -tttt -n port 53 and ether host not $MAC_CM |cut -d' ' -f 1-3,11,16 > $LIVEFILE &    
    
    
    #echo "formatting $TMPFILE into $OUTFILE"
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    #write header
    LO="publicIp,timestamp,ip,method,url,mac,friendlyName"
    echo $LO> $OUTFILE
    while read LINE; do
        if [ "$LINE" ]; then
            DAT=${LINE:0:19}
            DAT=${DAT//-/\/}
            MAC=${LINE:26:19}
            IP=${LINE:45}
            IP=${IP% *}
            IP=${IP%.*}
            URL=${LINE##* }
            URL=${URL%.*}
            #validate the URL length is greater than 4 chars and it contains at least one dot, otherwise do not add
            if [ ${#URL} -ge 4 ] && [ -n "${URL//[^.]/}" ]; then
                FRIENDLY=$(grep $MAC /tmp/dhcp.leases|cut -d' ' -f4 )
                echo "$PUBLICIP,$DAT,$IP,DNS,$URL,$MAC,$FRIENDLY">>$OUTFILE
            fi
        fi
    done < $TMPFILE
    cat $TMPFILE
    #echo "erasing  $TMPFILE "
    rm $TMPFILE
else #not running, just start tcpdump
    echo "not running alredy, starting process"
    tcpdump -e -Q in -tttt -n port 53 and ether host not $MAC_CM |cut -d' ' -f 1-3,11,16 > $LIVEFILE &
fi
