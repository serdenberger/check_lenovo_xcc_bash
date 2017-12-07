#!/bin/sh
#
# This script is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Script for monitoring sensors (temperature, fans and voltage) and 
# health of LENOVO servers using SNMPv3 to the xclarity controller (XCC).
#
# Version 0.0.2 2017-12-03
# add the compare with dot, just remove the dot, compate the bigger number
# remove SNMP v1, no longer supported by XCC
# usage help more accurate
# finish following checks: health, fans, voltage, temperature
# Version 0.0.1 2017-11-23
# based of the check_ibm_imm.sh from
# Ulric Eriksson <ulric.eriksson@dgc.se>
# modified by Silvio Erdenberger <serdenberger@lenovo.com>
#
# has to be ask for flex vs. rack/tower
# flex -> no fans maybe
# STATUS 0	
# STATUS 1	
# STATUS 2	
# STATUS 3	wrong parameter, device not available
#
##################################################################################
# requirements:
# installed programs on the nagios server
# snmpwalk, tr, 


SNMPWALK="/usr/bin/snmpwalk"

# Base OID is the 
# {iso(1) identified-organization(3) dod(6) internet(1) private(4) enterprise(1)}
BASEOID=.1.3.6.1.4.1
# 
# {LENOVO(19046) lenovoServerMibs(11)}
XCCOID=$BASEOID.19046.11.1

tempOID=$XCCOID.1.1
tempsOID=$tempOID.1.0
# Temperature sensor count
tempIndexOID=$tempOID.2.1.1
# Temperature sensor indexes
tempNameOID=$tempOID.2.1.2
# Names of temperature sensors
tempTempOID=$tempOID.2.1.3
tempFatalOID=$tempOID.2.1.5
tempCriticalOID=$tempOID.2.1.6
tempNoncriticalOID=$tempOID.2.1.7

voltOID=$XCCOID.1.2
voltsOID=$voltOID.1.0
voltIndexOID=$voltOID.2.1.1
voltNameOID=$voltOID.2.1.2
voltVoltOID=$voltOID.2.1.3
voltCritHighOID=$voltOID.2.1.6
voltCritLowOID=$voltOID.2.1.7

fanOID=$XCCOID.1.3
fansOID=$fanOID.1.0
fanIndexOID=$fanOID.2.1.1
fanNameOID=$fanOID.2.1.2
fanSpeedOID=$fanOID.2.1.3
fanMaxSpeedOID=$fanOID.2.1.8

healthStatOID=$XCCOID.1.4
# 255 = Normal, 0 = Critical, 2 = Non-critical Error, 4 = System-level Error

# 'label'=value[UOM];[warn];[crit];[min];[max]
# valid for temperatures
# fans and voltage the numbers for [warn];[crit];[min];[max] always empty

usage()
{
	echo "Usage: only snmpv3 supported by XCC"
	echo "authPriv     $0 -H host -u snmpv3User -l authPriv -a SHA -A AuthPW -x AES|DES -X PrivPW -T health|temperature|voltage|fans"
	echo "authNoPriv   $0 -H host -u snmpv3User -l authNoPriv -a SHA -A AuthPW -T health|temperature|voltage|fans"
	echo "noAuthNoPriv $0 -H host -u snmpv3User -l noAuthNoPriv -T health|temperature|voltage|fans"
}

get_health()
{
	echo "$HEALTH"|grep "^$1."|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_temperature()
{
        echo "$TEMP"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_voltage()
{
        echo "$VOLT"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

get_fan()
{
        echo "$FANS"|grep "^$2.*$1 = "|head -1|sed -e 's,^.*: ,,'|tr -d '"'
}

if test "$1" = -h; then
	usage
        exit 0
fi

while getopts "h:H:C:u:l:a:A:x:X:T:" o; do
	case "$o" in
	h )
		usage
                exit 3
		;;
	H )
		HOST="$OPTARG"
		;;
	C )
		usage
                exit 3
		;;
	u )
		USER="$OPTARG"
		;;
	l )
		SECLVL="$OPTARG"
		;;
	a )
		AENC="$OPTARG"
		;;
	A )
		APW="$OPTARG"
		;;
	x )
		PENC="$OPTARG"
		;;
	X )
		PPW="$OPTARG"
		;;
	T )
		TEST="$OPTARG"
		;;
	* )
		usage
                exit 3
		;;
	esac
done

#SNMPOPTS=" -v 1 -c $COMMUNITY -On -t 5 $HOST"
case "$SECLVL" in
authPriv )
	SNMPOPTS=" -v 3 -l $SECLVL -u $USER -x $PENC -X $PPW -a $AENC -A $APW -On -t 5 $HOST"
	;;
authNoPriv )
	SNMPOPTS=" -v 3 -l $SECLVL -u $USER -a $AENC -A $APW -On -t 5 $HOST"
	;;
noAuthNoPriv )
	SNMPOPTS=" -v 3 -l $SECLVL -u $USER -On -t 5 $HOST"
	;;
* )
	echo "Your command line contains errors" 
	echo "OPTS= -l $SECLVL -u $USER -x $PENC -X $PPW -a $AENC -A $APW HOST $HOST -T $TEST"
	usage
	exit 3
	;;
esac

RESULT=''
STATUS=0	# OK

case "$TEST" in
health )
	HEALTH=`$SNMPWALK $SNMPOPTS $healthStatOID`
	healthStat=`get_health $healthStatOID`
	case "$healthStat" in
	0 )
		RESULT="Health status: Critical"
		STATUS=2	# Critical
		;;
	2 )
		RESULT="Health status: Non-critical error"
		STATUS=1
		;;
	4 )
		RESULT="Health status: System level error"
		STATUS=2
		;;
	255 )
		RESULT="Health status: Normal"
                STATUS=0
		;;
	* )
		RESULT="Health status: Unknown"
		STATUS=3
		;;
	esac
	;;
temperature )
	TEMP=`$SNMPWALK $SNMPOPTS $tempOID`
	# Figure out which temperature indexes we have
	temps=`echo "$TEMP"|
	grep -F "$tempIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$temps"; then
		RESULT="No temperatures"
		STATUS=3
	fi
	for i in $temps; do
		tempName=`get_temperature $i $tempNameOID`
		tempTemp=`get_temperature $i $tempTempOID`
		tempTempInt=$(echo $tempTemp | tr -d .)
		tempFatal=`get_temperature $i $tempFatalOID`
		tempCritical=`get_temperature $i $tempCriticalOID`
		if [[ "$tempCritical" == "N/A" ]]; then tempCritical=0 ; fi
		tempCriticalInt=$(echo $tempCritical | tr -d .)
		tempNoncritical=`get_temperature $i $tempNoncriticalOID`
		if [[ "$tempNoncritical" == "N/A" ]]; then tempNoncritical=0 ; fi
		tempNoncriticalInt=$(echo $tempNoncritical | tr -d .)
		# an linefeed insert, this is because of two lines
		RESULT="$RESULT$tempName = $tempTemp
"
		if test "$tempCriticalInt" -gt 0; then
			if test "$tempTempInt" -ge "$tempCriticalInt"; then
				STATUS=2
			elif test "$tempTempInt" -ge "$tempNoncriticalInt"; then
				STATUS=1
			fi
		fi
		PERFDATA="${PERFDATA}'$tempName'=$tempTemp;$tempNoncritical;$tempCritical;; "
	done
	;;
voltage )
	VOLT=`$SNMPWALK $SNMPOPTS $voltOID`
	volts=`echo "$VOLT"|
	grep -F "$voltIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$volts"; then
		RESULT="No voltages"
		STATUS=3
	fi
	for i in $volts; do
		voltName=`get_voltage $i $voltNameOID`
		voltVolt=`get_voltage $i $voltVoltOID`
		voltVoltInt=$(echo $voltVolt | tr -d .)
		voltCritHigh=`get_voltage $i $voltCritHighOID`
		if [[ "$voltCritHigh" == "N/A" ]]; then voltCritHigh=0 ; fi
		voltCritHighInt=$(echo $voltCritHigh | tr -d .)
		voltCritLow=`get_voltage $i $voltCritLowOID`
		if [[ "$voltCritLow" == "N/A"  ]]; then voltCritLow=0 ; fi
		voltCritLowInt=$(echo $voltCritLow | tr -d .)
		RESULT="$RESULT$voltName = $voltVolt
"
		if test "$voltCritLowInt" -gt 0 -a "$voltVoltInt" -le "$voltCritLowInt"; then
			#echo "$voltVolt < $voltCritLow"
			STATUS=2
		elif test "$voltCritHighInt" -gt 0 -a "$voltVoltInt" -ge "$voltCritHighInt"; then
			#echo "$voltVolt > $voltCritLow"
			STATUS=2
		fi
		PERFDATA="${PERFDATA}'$voltName'=$voltVolt;;;; "
	done
	;;
fans )
	FANS=`$SNMPWALK $SNMPOPTS $fanOID`
	fans=`echo "$FANS"|
	grep -F "$fanIndexOID."|
	sed -e 's,^.*: ,,'`
	if test -z "$fans"; then
		RESULT="No fans"
		STATUS=3
	fi
	for i in $fans; do
		fanName=`get_fan $i $fanNameOID`
		fanSpeed=`get_fan $i $fanSpeedOID|tr -d 'h '| sed -e 's/ofmaximum//g'`
		RESULT="$RESULT$fanName = $fanSpeed
"
		fanSpeedPerf=`echo $fanSpeed | sed -e 's/offline/0/g'`
		PERFDATA="${PERFDATA}'$fanName'=$fanSpeedPerf;;;; "
	done
	;;
* )
	usage
        exit 3
	;;
esac

echo "$RESULT|$PERFDATA"
exit $STATUS

