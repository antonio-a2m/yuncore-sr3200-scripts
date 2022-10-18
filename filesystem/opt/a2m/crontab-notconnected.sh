#!/bin/ash
# detects the nearby wifi devices not necesarilly connected
# to this router, just by being nearby.
# This is achieved by monitoring with airodump-ng
# and formats the data to a csv
# This script is meant to be executed by a crontab
# * * * * * /opt/a2m/crontab-not-connected.sh 
# Needs  a monitor network interface called wlanmon
#
# Mac Address Randomization in clients
# prevent this mechanismo to work as intended
#
# Antonio Gonzalez aggarcia@gmail.com
# Oct 2020, the year of covid


# variables
MONIFACE=wlanmon
PRETMPFILE=/tmp/a2m-not-connected
COLLECTPATH=/tmp/a2m-collect
AIRODUMPSUFFIX="-01.csv"
TMPFILE=${PRETMPFILE}${AIRODUMPSUFFIX}
DATE=$(/bin/date +"%Y_%m_%d_%H_%M_%S")
OUTFILE=/tmp/airodumpdata-$DATE.csv

# capture during 30 secs
/usr/bin/timeout --foreground 30  /usr/sbin/airodump-ng --output-format csv -w $PRETMPFILE $MONIFACE 



# remove DOS newlines and remove null chars
sed -e "s/\r//g" $TMPFILE | tr -d '\000' > ${TMPFILE}_tmp
mv ${TMPFILE}_tmp ${TMPFILE} 


# where non-access points section starts, since AP data is not relevant
# only WIFI clients 
LINENUM=$(expr $(grep -n Station $TMPFILE |cut -d ':' -f 1) + 1)

#use only clents section
tail +$LINENUM $TMPFILE|tr -s ' '| sed -e 's/,/|/1' | sed -e 's/,/|/1' | sed -e 's/,/|/1' | sed -e 's/,/|/1' | sed -e 's/,/|/1'| sed -e 's/,/|/1' > ${OUTFILE}
rm $TMPFILE
