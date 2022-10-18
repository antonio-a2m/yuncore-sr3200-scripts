#!/bin/ash
# This script checks the freemem percentage
# If it reaches the LIMIT (10%) of free RAM, it stops the non-vital processes
# If after that, the is at least MIN2RESTART (40%) of free ram
# the processes are restarted
#
# to simulate filling the RAM artificially and test, use the following command
# cat /dev/zero| head -c 90000000 |pv -L 2000000| tail

#
# Antonio Gonzalez aggarcia@gmail.com
# Dec 2020, the year of covid



TOT=$(head -n1 /proc/meminfo |tr -s ' '|cut -d' ' -f2)
FREE=$(head -n3 /proc/meminfo|tail -n1 |tr -s ' '|cut -d' ' -f2)
PERC=$(expr $FREE \* 100 / $TOT); 
LIMIT=10 #when mem reaches this free percentage, do the action
MIN2RESTART=40
logger memfree $PERC\%

if [ $PERC -lt  $LIMIT ]; then
    logger MEM LOW, killing stuff

    PS2SRCH=airodump-ng
    #search airmon pid and kill it
    RUNNING_MONITOR=$(ps|grep $PS2SRCH |grep -v grep|wc -l)
    logger "::::::::::::::$RUNNING_MONITOR monitors active;;;;"
    if [ $RUNNING_MONITOR -gt 0 ]; then
        PIDMON=$(ps|grep $PS2SRCH |grep -v grep|head -n1|xargs|cut -d' ' -f1)
        logger "=====================killing $PS2SRCH PID $PIDMON"
        KILLED=$(/bin/kill -9 $PIDMON)
        logger "=====================killed $PS2SRCH $KILLED ;;;;"
    fi
    
    logger "=====================stopping squid"
    /etc/init.d/squid stop
    #after killing stuff, report memory released

    TOT=$(head -n1 /proc/meminfo |tr -s ' '|cut -d' ' -f2)
    FREE=$(head -n3 /proc/meminfo|tail -n1 |tr -s ' '|cut -d' ' -f2)
    PERC=$(expr $FREE \* 100 / $TOT); 
    logger "=====================usage after killing $PERC"

    #if there is at leaset MIN2RESTART free, restart processes
    if [ $PERC -ge $MIN2RESTART ]; then
        #command to restart airmon again
        /opt/a2m/monitor-nearby.sh &
        #reiniciar squid
        /etc/init.d/squid start
    fi
else
    logger MEM ok, not killing anything
fi
