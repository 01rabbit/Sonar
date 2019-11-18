#!/bin/sh

#Requirements: aircrack-ng suite
###Declaring all the variables used####
PROGNAME=$(basename $0)
VERSION="1.0"
INTERCEPT=intercept
ADAPTOR="monitor_interface"
TIME=5 
USER=`whoami`
POWER="dbm"
OUI="oui"
VENDER="vendor name"
RATE="encout"
BSSID="BSSID"
LOOP="FALSE"
DATE=`date '+%Y%m%d%H%M%S'`
MAC_HIST="Encount MAC history"
###END of Variables Declaration###

#oui.txt
#http://standards-oui.ieee.org/oui.txt

#help function
usage ()
{
    printf "Usage: $PROGNAME [\e[32;1mOPTIONS\e[m] <\e[31;1mMonitor Mode Wireless Interface\e[m> \n"
    echo
    printf "\e[32;1mOptions\e[m:"
    echo ""
    echo "  -l : Loop"
    echo "  -t : interval of loop 5-120"
    echo "  -d : Delete MAC history"
    echo "  -i : Wireless Interface"
    echo "  -h : Display this help" 
    echo
    printf  "\e[34;1mExample\e[m: \n"
    echo "      $PROGNAME -i <interface> "
    echo "      $PROGNAME -l -i <interface>"
    echo "      $PROGNAME -l -t 30 -i <interface>"
    printf "\e[31;1mMonitor Mode Wireless Interface\e[m:\n"
    echo "  It is necessary to shift to the monitoring mode with the following command."
    echo 
    echo "  airmon-ng start <your wireless interface>"
    echo
}

header ()
{
    clear
    printf "\n\e[34;1m---------------------------------------------------------------------\e[m\n"
    printf "       ________  _  _____   ___   \e[36m          ('                        \e[m\n"
    printf "      / __/ __ \/ |/ / _ | / _ \  \e[36m          +                         \e[m\n"
    printf "     _\ \/ /_/ /    / __ |/ , _/  \e[36m       .F+.-                        \e[m\n"
    printf "    /___/\____/_/|_/_/ |_/_/|_|   \e[36m       ..b&.p....                   \e[m\n"
    printf "          Version : $VERSION      \e[36m          .jm+++MMM^_M]                  \e[m\n"
    printf "\e[36m .(,           ........   ........    .MMMMMMMMMaJMN                  \e[m\n"
    printf "\e[36m .MM, ...gNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMa.    \e[m\n"
    printf "\e[36m ,MMMMMMMMMMNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNMMMMMMMMMMMMMMMMMMMMMMb    \e[m\n"
    printf "\e[36m,WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF    \e[m\n"
    printf "\e[34;1m----------------------------------------------------------------------\e[m\n"
    echo
}

check_root ()
{
    if [ $USER != "root" ];then
        usage
        printf "Please Run as \e[31;1mroot\e[m\n"
        exit 0
    fi
}

mac_history ()
{
    MAC_HIST="history_"$DATE
    echo $MAC_HIST
}

intercept ()
{
    if [ $ADAPTOR = "monitor_interface" ];then
        usage
        exit 1
    fi
    
    if [ -e "$INTERCEPT"*  ];then
        rm ./"$INTERCEPT"*
    fi

    xterm  -geometry -1 -e  airodump-ng $ADAPTOR -w $INTERCEPT --output-format csv --ignore-negative-one &
    sleep $TIME
    killall airodump-ng
    sleep 1
    
    cat "$INTERCEPT"-01.csv | sed -n '/Station MAC/,$p'|sort -k6nr|grep - > work.csv
    cat work.csv |cut -d ',' -f1 > station
}

view ()
{
    header

    echo " POWER  STA MAC           BSSID             RATE  STA MAC Vender"
    echo "------------------------------------------------------------------"
    for MACADDR in $(cat station) 
    do

        POWER=$(grep -m 1 ${MACADDR} work.csv|awk -F '[,]' '{print $4}') 
        OUI=$(echo ${MACADDR}|cut -c 1-8|tr 'a-f:' 'A-F-')
        #OUI=$(echo ${MACADDR}|cut -c 1-8|sed -e 's/://g')
        VENDER=$(grep ${OUI} oui.txt |cut -d ' ' -f 4-|sed -e 's/(hex)//g' )
        
        
        if [ ${POWER} -ge -99 -a ${POWER} -lt -70 ];then
            printf "\e[31m${POWER}dbm \e[m"
        elif [ ${POWER} -ge -70 -a ${POWER} -lt -40 ];then
            printf "\e[33m${POWER}dbm \e[m"
        elif [ ${POWER} -eq -1 ]; then
            continue
        else
            printf "\e[32m${POWER}dbm \e[m"
        fi

        if ls ./history_* > /dev/null 2>&1 
        then
            if sort history_* | uniq|grep ${MACADDR} > /dev/null; then
                printf "\e[31;1m${MACADDR}\e[m"
                RATE=$(sort history_* |uniq -c|grep ${MACADDR}|cut -b 3-7)
            else
                printf "${MACADDR}"
                RATE=0
            fi
        else
            printf "${MACADDR}"
            RATE=0
        fi

        BSSID=$(grep  ${MACADDR} work.csv|awk -F '[,]' '{print $6}')
        if [ "${BSSID}" = " (not associated) " ];then
            printf "\e[30m${BSSID}\e[m"
        else
            printf "\e[32m${BSSID}\e[m"
        fi

        printf "%5s " $RATE

        echo ${VENDER}> temp
        VENDER=$(sed -e 's/"\t"//g' temp)
        printf " ${VENDER}\n"
        
    done

    sleep 2
}

footer ()
{
    if [ -e temp ];then
        rm ./temp
    fi

    if [ -e "$INTERCEPT"*  ];then
        rm ./"$INTERCEPT"*
    fi

    if [ -e station ];then
        cat station >> $MAC_HIST
        rm ./station
    fi
    }

# Check argument
if [ $# -eq 0 ];then
    usage
    exit 1
else
    while getopts i:ldt:h OPT
    do
        case $OPT in
            "i" ) FLG_I="TRUE" ; VALUE_I="$OPTARG" ;;
            "l" ) FLG_L="TRUE" ;;
            "d" ) FLG_D="TRUE" ;;
            "t" ) FLG_T="TRUE" ; VALUE_T="$OPTARG" ;;
            "h" ) FLG_H="TRUE" ;;
            * ) usage; exit;;
        esac
    done
fi

# set option
if [ "$FLG_I" = "TRUE" ]; then
    iwconfig $VALUE_I > temp
    if [ -e temp ]; then
        if cat temp|grep Monitor >/dev/null ;then
            ADAPTOR=$VALUE_I
            rm ./temp
        else
            usage
            printf "\e[33;1mNote\e[m Please change to \e[31;1mMonitor\e[m mode\n"
            rm ./temp
            exit 1
        fi
    else
        usage
        echo '\e[33;1mNote\e[m Please connect your wireless Interface'
        exit 1
    fi
fi

if [ "$FLG_L" = "TRUE" ]; then #loop
    LOOP="TRUE"
fi

if [ "$FLG_D" = "TRUE" ]; then #delete
    printf "Do you want to delete all history? :"
    read INPUT
    if [ -z $INPUT ]; then
        echo "Please enter yes or no"
        exit 1
    elif [ $INPUT = "yes" ] || [ $INPUT = "YES" ] || [ $INPUT = "y" ]; then
        if ls ./history_* > /dev/null 2>&1 ; then
            rm history_*
        fi
        exit 0
    elif [ $INPUT = "no" ] || [ $INPUT = "NO" ] || [ $INPUT = "n" ]; then
        exit 1
    else
        echo "Please enter yes or no"
        exit 1
    fi
fi

if [ "$FLG_T" = "TRUE" ]; then #time
    if [ $VALUE_T -ge 5  -a $VALUE_T -le 120 ];then
        TIME=$VALUE_T
    else
        usage
        echo 'Input value error'
        exit 1
    fi
fi

if [ "$FLG_H" = "TRUE" ]; then #help
    header
    usage
    exit 0
fi

### main routine ##

## Check Authority
check_root
mac_history
clear

while :
do
    intercept
    view
    footer
    if [ $LOOP = "FALSE" ]; then
        break
    fi
done





