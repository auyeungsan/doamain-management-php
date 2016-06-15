#!/bin/bash
PATH=/bin:/usr/bin:/usr/local/bin:/usr/local/ssl/bin:/usr/sfw/bin ; export PATH

# Who to page when an expired domain is detected (cmdline: -e)
ADMIN="san.auyeung@lazybugstudio.com"
#ADMIN="radek.chan@lazybugstudio.com"

# Number of days in the warning threshhold  (cmdline: -x)
WARNDAYS=30

# If QUIET is set to TRUE, don't print anything on the console (cmdline: -q)
QUIET="FALSE"

# Don't send emails by default (cmdline: -a)
ALARM="FALSE"

# Whois server to use (cmdline: -s)
WHOIS_SERVER="whois.internic.org"

# Location of system binaries
AWK="/usr/bin/awk"
WHOIS="/usr/bin/whois"
TIMEOUT="/usr/bin/timeout"
DATE="/bin/date"
CUT="/usr/bin/cut"
MAIL="/bin/mail"
# Place to stash temporary files
WHOIS_TMP="/var/tmp/whois.$$"

logPath="/tmp"

if [ ! -f "$logPath/domain-check-daily.log" ]; then
	touch $logPath/domain-check-daily.log
fi


#############################################################################
# Purpose: Convert a date from MONTH-DAY-YEAR to Julian format
# Acknowledgements: Code was adapted from examples in the book
#                   "Shell Scripting Recipes: A Problem-Solution Approach"
#                   ( ISBN 1590594711 )
# Arguments:
#   $1 -> Month (e.g., 06)
#   $2 -> Day   (e.g., 08)
#   $3 -> Year  (e.g., 2006)
#############################################################################
date2julian()
{
    if [ "${1} != "" ] && [ "${2} != ""  ] && [ "${3}" != "" ]
    then
         ## Since leap years add aday at the end of February,
         ## calculations are done from 1 March 0000 (a fictional year)
         d2j_tmpmonth=$((12 * ${3} + ${1} - 3))

          ## If it is not yet March, the year is changed to the previous year
          d2j_tmpyear=$(( ${d2j_tmpmonth} / 12))

          ## The number of days from 1 March 0000 is calculated
          ## and the number of days from 1 Jan. 4713BC is added
          echo $(( (734 * ${d2j_tmpmonth} + 15) / 24 -  2 * ${d2j_tmpyear} + ${d2j_tmpyear}/4
                        - ${d2j_tmpyear}/100 + ${d2j_tmpyear}/400 + $2 + 1721119 ))
    else
          echo 0
    fi
}

#############################################################################
# Purpose: Convert a string month into an integer representation
# Arguments:
#   $1 -> Month name (e.g., Sep)
#############################################################################
getmonth()
{
       LOWER=`tolower $1`

       case ${LOWER} in
             jan) echo 1 ;;
             feb) echo 2 ;;
             mar) echo 3 ;;
             apr) echo 4 ;;
             may) echo 5 ;;
             jun) echo 6 ;;
             jul) echo 7 ;;
             aug) echo 8 ;;
             sep) echo 9 ;;
             oct) echo 10 ;;
             nov) echo 11 ;;
             dec) echo 12 ;;
               *) echo  0 ;;
       esac
}

#############################################################################
# Purpose: Calculate the number of seconds between two dates
# Arguments:
#   $1 -> Date #1
#   $2 -> Date #2
#############################################################################
date_diff()
{
        if [ "${1}" != "" ] &&  [ "${2}" != "" ]
        then
                echo $(expr ${2} - ${1})
        else
                echo 0
        fi
}

##################################################################
# Purpose: Converts a string to lower case
# Arguments:
#   $1 -> String to convert to lower case
##################################################################
tolower()
{
     LOWER=`echo ${1} | tr [A-Z] [a-z]`
     echo $LOWER
}

##################################################################
# Purpose: Access whois data to grab the registrar and expiration date
# Arguments:
#   $1 -> Domain to check
##################################################################
check_domain_status()
{
    local REGISTRAR=""
    # Avoid WHOIS LIMIT EXCEEDED - slowdown our whois client by adding 3 sec
    sleep 3
    # Save the domain since set will trip up the ordering
    DOMAIN=${1}
    TLDTYPE="`echo ${DOMAIN} | cut -d '.' -f3 | tr '[A-Z]' '[a-z]'`"
    if [ "${TLDTYPE}"  == "" ];
    then
            TLDTYPE="`echo ${DOMAIN} | cut -d '.' -f2 | tr '[A-Z]' '[a-z]'`"
    fi

    # Invoke whois to find the domain registrar and expiration date
    # ${TIMEOUT} 20 ${WHOIS} -h ${WHOIS_SERVER} "=${1}" > ${WHOIS_TMP}
    # Let whois select server
    if [ "${TLDTYPE}"  == "org" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.pir.org" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "in" ]; # India
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.registry.in" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "uk" ]; # United Kingdom
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.nic.uk" "${1}" > ${WHOIS_TMP}

    elif [ "${TLDTYPE}"  == "biz" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.neulevel.biz" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "info" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.afilias.info" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "jp" ]; # Japan
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.jprs.jp" "${1}" > ${WHOIS_TMP}

    elif [ "${TLDTYPE}"  == "ca" ]; # Canada
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.cira.ca" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "co" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.nic.co" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "tw" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.twnic.net.tw" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "cc" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.nic.cc" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "online" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.nic.online" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "xyz" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.nic.xyz" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "mobi" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.dotmobiregistry.net" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "site" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.centralnic.com" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "studio" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.rightside.co" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "today" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h "whois.donuts.co" "${1}" > ${WHOIS_TMP}
    elif [ "${TLDTYPE}"  == "cn" ];
    then
        count=0
        while [ $count -le 3 ];do
                whoisResult=$( ${TIMEOUT} 20 ${WHOIS} -h "whois.cnnic.net.cn" "${1}" > ${WHOIS_TMP})
		expiryDate=$(grep "Expiration Time" ${WHOIS_TMP})
                (( count++ ))
                if [ "$expiryDate" ];then
                        break
                fi
		sleep 2
        done
    elif [ "${TLDTYPE}"  == "com" -o "${TLDTYPE}"  == "net" -o "${TLDTYPE}"  == "edu" ];
    then
         ${TIMEOUT} 20 ${WHOIS} -h ${WHOIS_SERVER} "=${1}" > ${WHOIS_TMP}
    else
         ${TIMEOUT} 20 ${WHOIS} "${1}" > ${WHOIS_TMP}
    fi

    # Parse out the expiration date and registrar -- uses the last registrar it finds
    REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} -F: '/Registrar/ && $2 != ""  { REGISTRAR=substr($2,2,17) } END { print REGISTRAR }'`

    if [ "${TLDTYPE}" == "mobi" ];
    then
        REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} '/Sponsoring Registrar:/ { print $2 }'| cut -d':' -f2`
    elif [ "${TLDTYPE}" == "biz" ];
    then
        REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} -F: '/Registrar:/ && $2 != ""  { REGISTRAR=substr($2,20,17) } END { print REGISTRAR }'`
    elif [ "${TLDTYPE}" == "co" -o "${TLDTYPE}" == "info" -o "${TLDTYPE}" == "org" -o "${TLDTYPE}" == "xyz" -o "${TLDTYPE}" == "studio" -o "${TLDTYPE}" == "today" -o "${TLDTYPE}" == "online" ];
    then
	REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} '/Sponsoring Registrar:/ { print $3 }'`
    elif [ "${TLDTYPE}" == "tw" ];
    then
        REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} '/Registration Service Provider:/ { print $4 }'`
    elif [ "${TLDTYPE}" == "cn" ];
    then
        REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} '/Registrant:/ { print $2 }'`
    elif [ "${TLDTYPE}" == "hk" ];
    then
        REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} '/Registrar Name:/ { print $3 }'`
    else
#        REGISTRAR="Unknown"
        REGISTRAR=`cat ${WHOIS_TMP} | ${AWK} '/Registrar:/ {print $2}'`
    fi

    if [ "$REGISTRAR" == "ENOM," -o "$REGISTRAR" == "eNom," -o "$REGISTRAR" == "ENom" -o "$REGISTRAR" == "NAMECHEAP," -o "$REGISTRAR" == "NameCheap," ];then
        REGISTRAR="NameCheap"
    fi

    if [ "$REGISTRAR" == "GoDaddy.com," -o "$REGISTRAR" == "GODADDY.COM," ];then
        REGISTRAR="GoDaddy"
    fi

    # If the Registrar is NULL, then we didn't get any data
#    if [ "${REGISTRAR}" = "" ]
#    then
#        prints "$DOMAIN" "Unknown" "Unknown" "Unknown" "Unknown"
#        return
#    fi

    # The whois Expiration data should resemble the following: "Expiration Date: 09-may-2008"

    # for .in, .info, .org domains
    if [ "${TLDTYPE}" == "in" -o "${TLDTYPE}" == "info" -o "${TLDTYPE}" == "org" ];
    then
            tdomdate=`cat ${WHOIS_TMP} | ${AWK} '/Expiry Date:/ { print $4 }'`
            tyear=`echo ${tdomdate} | cut -d'-' -f1`
            tmon=`echo ${tdomdate} | cut -d'-' -f2`
               case ${tmon} in
                     1|01) tmonth=jan ;;
                     2|02) tmonth=feb ;;
                     3|03) tmonth=mar ;;
                     4|04) tmonth=apr ;;
                     5|05) tmonth=may ;;
                     6|06) tmonth=jun ;;
                     7|07) tmonth=jul ;;
                     8|08) tmonth=aug ;;
                     9|09) tmonth=sep ;;
                     10)tmonth=oct ;;
                     11) tmonth=nov ;;
                     12) tmonth=dec ;;
                      *) tmonth=0 ;;
                esac
            tday=`echo ${tdomdate} | cut -d'-' -f3 |cut -d'T' -f1`
            DOMAINDATE=`echo $tday-$tmonth-$tyear`
    elif [ "${TLDTYPE}" == "biz" -o "${TLDTYPE}" == "co" ]; # for .biz domain
    then
            DOMAINDATE=`cat ${WHOIS_TMP} | awk '/Domain Expiration Date:/ { print $6"-"$5"-"$9 }'`
    elif [ "${TLDTYPE}" == "uk" ]; # for .uk domain
    then
            DOMAINDATE=`cat ${WHOIS_TMP} | awk '/Renewal date:/ || /Expiry date:/ { print $3 }'`
    elif [ "${TLDTYPE}" == "jp" ]; # for .jp 2010/04/30
    then
            tdomdate=`cat ${WHOIS_TMP} | awk '/Expires on/ { print $3 }'`
            tyear=`echo ${tdomdate} | cut -d'/' -f1`
            tmon=`echo ${tdomdate} | cut -d'/' -f2`
               case ${tmon} in
                     1|01) tmonth=jan ;;
                     2|02) tmonth=feb ;;
                     3|03) tmonth=mar ;;
                     4|04) tmonth=apr ;;
                     5|05) tmonth=may ;;
                     6|06) tmonth=jun ;;
                     7|07) tmonth=jul ;;
                     8|08) tmonth=aug ;;
                     9|09) tmonth=sep ;;
                     10)tmonth=oct ;;
                     11) tmonth=nov ;;
                     12) tmonth=dec ;;
                      *) tmonth=0 ;;
                esac
            tday=`echo ${tdomdate} | cut -d'/' -f3`
            DOMAINDATE=`echo $tday-$tmonth-$tyear`
    elif [ "${TLDTYPE}" == "ca" ]; # for .ca 2010/04/30
    then
            tdomdate=`cat ${WHOIS_TMP} | awk '/Expiry date/ { print $3 }'`
            tyear=`echo ${tdomdate} | cut -d'/' -f1`
            tmon=`echo ${tdomdate} | cut -d'/' -f2`
               case ${tmon} in
                     1|01) tmonth=jan ;;
                     2|02) tmonth=feb ;;
                     3|03) tmonth=mar ;;
                     4|04) tmonth=apr ;;
                     5|05) tmonth=may ;;
                     6|06) tmonth=jun ;;
                     7|07) tmonth=jul ;;
                     8|08) tmonth=aug ;;
                     9|09) tmonth=sep ;;
                     10)tmonth=oct ;;
                     11) tmonth=nov ;;
                     12) tmonth=dec ;;
                      *) tmonth=0 ;;
                esac
            tday=`echo ${tdomdate} | cut -d'/' -f3`
            DOMAINDATE=`echo $tday-$tmonth-$tyear`
    elif [ "${TLDTYPE}" == "hk" ];
    then
            tdomdate=`cat ${WHOIS_TMP} | awk '/Expiry Date/ { print $3 }'`
            tyear=`echo ${tdomdate} | cut -d'-' -f3`
            tmon=`echo ${tdomdate} | cut -d'-' -f2`
               case ${tmon} in
                     1|01) tmonth=jan ;;
                     2|02) tmonth=feb ;;
                     3|03) tmonth=mar ;;
                     4|04) tmonth=apr ;;
                     5|05) tmonth=may ;;
                     6|06) tmonth=jun ;;
                     7|07) tmonth=jul ;;
                     8|08) tmonth=aug ;;
                     9|09) tmonth=sep ;;
                     10)tmonth=oct ;;
                     11) tmonth=nov ;;
                     12) tmonth=dec ;;
                      *) tmonth=0 ;;
                esac
            tday=`echo ${tdomdate} | cut -d'-' -f1`
            DOMAINDATE=`echo $tday-$tmonth-$tyear`
    elif [ "${TLDTYPE}" == "tw" ];
    then
            tdomdate=`cat ${WHOIS_TMP} | awk '/Record expires/ { print $4 }'`
            tyear=`echo ${tdomdate} | cut -d'-' -f1`
            tmon=`echo ${tdomdate} | cut -d'-' -f2`
               case ${tmon} in
                     1|01) tmonth=jan ;;
                     2|02) tmonth=feb ;;
                     3|03) tmonth=mar ;;
                     4|04) tmonth=apr ;;
                     5|05) tmonth=may ;;
                     6|06) tmonth=jun ;;
                     7|07) tmonth=jul ;;
                     8|08) tmonth=aug ;;
                     9|09) tmonth=sep ;;
                     10)tmonth=oct ;;
                     11) tmonth=nov ;;
                     12) tmonth=dec ;;
                      *) tmonth=0 ;;
                esac
            tday=`echo ${tdomdate} | cut -d'-' -f3`
            DOMAINDATE=`echo $tday-$tmonth-$tyear`
    elif [ "${TLDTYPE}" == "cc" -o "${TLDTYPE}" == "online" -o "${TLDTYPE}" == "xyz" -o "${TLDTYPE}" == "studio" -o "${TLDTYPE}" == "today" ];
    then
        tdomdate=`cat ${WHOIS_TMP} | awk '/Registry Expiry Date/ { print $4 }'`
        tyear=`echo ${tdomdate} | cut -d'-' -f1`
        tmon=`echo ${tdomdate} | cut -d'-' -f2`
               case ${tmon} in
                     1|01) tmonth=jan ;;
                     2|02) tmonth=feb ;;
                     3|03) tmonth=mar ;;
                     4|04) tmonth=apr ;;
                     5|05) tmonth=may ;;
                     6|06) tmonth=jun ;;
                     7|07) tmonth=jul ;;
                     8|08) tmonth=aug ;;
                     9|09) tmonth=sep ;;
                     10)tmonth=oct ;;
                     11) tmonth=nov ;;
                     12) tmonth=dec ;;
                      *) tmonth=0 ;;
                esac
        tday=`echo ${tdomdate} | cut -d'-' -f3 | awk -F 'T' '{print$1}'`
        DOMAINDATE=`echo $tday-$tmonth-$tyear`
    elif [ "${TLDTYPE}" == "cn" ];
    then
        tdomdate=`cat ${WHOIS_TMP} | awk '/Expiration Time/ { print $3 }'`
        tyear=`echo ${tdomdate} | cut -d'-' -f1`
        tmon=`echo ${tdomdate} | cut -d'-' -f2`
               case ${tmon} in
                     1|01) tmonth=jan ;;
                     2|02) tmonth=feb ;;
                     3|03) tmonth=mar ;;
                     4|04) tmonth=apr ;;
                     5|05) tmonth=may ;;
                     6|06) tmonth=jun ;;
                     7|07) tmonth=jul ;;
                     8|08) tmonth=aug ;;
                     9|09) tmonth=sep ;;
                     10)tmonth=oct ;;
                     11) tmonth=nov ;;
                     12) tmonth=dec ;;
                      *) tmonth=0 ;;
                esac
        tday=`echo ${tdomdate} | cut -d'-' -f3`
        DOMAINDATE=`echo $tday-$tmonth-$tyear`
    elif [ "${TLDTYPE}" == "mobi" ];
    then
        tdomdate=`cat ${WHOIS_TMP} | awk '/Expiration Date/ { print $2 }'`
        tyear=`echo ${tdomdate} |cut -d':' -f2| cut -d'-' -f3`
        tmon=`echo ${tdomdate} |cut -d':' -f2| cut -d'-' -f2`
        tday=`echo ${tdomdate} |cut -d':' -f2| cut -d'-' -f1`
        DOMAINDATE=`echo $tday-$tmon-$tyear`
    else # .com, .edu, .net and may work with others
            DOMAINDATE=`cat ${WHOIS_TMP} | ${AWK} '/Expiration/ { print $NF }'`
    fi

    NOMATCH=`egrep "Registrar|Registration" ${WHOIS_TMP}`
    if [ ! "$NOMATCH" ];
    then
        echo "${DOMAIN} not found in whois record" | tee -a $logPath/domain-results
        return
    fi

    #echo $DOMAINDATE # debug
    # Whois data should be in the following format: "13-feb-2006"
    IFS="-"
    set -- ${DOMAINDATE}
    MONTH=$(getmonth ${2})
    IFS=""

    # Convert the date to seconds, and get the diff between NOW and the expiration date
    DOMAINJULIAN=$(date2julian ${MONTH} ${1#0} ${3})
    DOMAINDIFF=$(date_diff ${NOWJULIAN} ${DOMAINJULIAN})

    if [ ${DOMAINDIFF} -lt 0 ]
    then
          if [ "${ALARM}" = "TRUE" ]
          then
                echo "${DOMAIN} ${DOMAINDATE} expired!" >> $logPath/domain-results
#                echo "The domain ${DOMAIN} has expired!" \
#                | ${MAIL} -r "domaincheck@radek.test.vm (Domain Check)" -s "Domain ${DOMAIN} has expired!" ${ADMIN}
           fi

           prints ${DOMAIN} "Expired" "${DOMAINDATE}" "${DOMAINDIFF}" ${REGISTRAR} | tee -a $logPath/domain-check.log

    elif [ ${DOMAINDIFF} -lt ${WARNDAYS} ]
    then
           if [ "${ALARM}" = "TRUE" ]
           then
                echo "${DOMAIN} ${DOMAINDATE} ${DOMAINDIFF} days left" >> $logPath/domain-results
#                    echo "The domain ${DOMAIN} will expire on ${DOMAINDATE}" \
#                    | ${MAIL} -r "domaincheck@radek.test.vm (Domain Check)" -s "Domain ${DOMAIN} will expire in ${WARNDAYS}-days or less" ${ADMIN}
            fi
            prints ${DOMAIN} "Expiring" "${DOMAINDATE}" "${DOMAINDIFF}" "${REGISTRAR}" | tee -a $logPath/domain-check.log
     else
            prints ${DOMAIN} "Valid" "${DOMAINDATE}"  "${DOMAINDIFF}" "${REGISTRAR}" | tee -a $logPath/domain-check.log
     fi


}

####################################################
# Purpose: Print a heading with the relevant columns
# Arguments:
#   None
####################################################
print_heading()
{
        if [ "${QUIET}" != "TRUE" ]
        then
                printf "\n%-1s %-1s %-1s %-1s %-1s\n" "Domain" "Registrar" "Status" "Expires" "Days Left"
                echo "----------------------------------- ----------------- -------- ----------- ---------"
        fi
}

#####################################################################
# Purpose: Print a line with the expiraton interval
# Arguments:
#   $1 -> Domain
#   $2 -> Status of domain (e.g., expired or valid)
#   $3 -> Date when domain will expire
#   $4 -> Days left until the domain will expire
#   $5 -> Domain registrar
#####################################################################
prints()
{
    if [ "${QUIET}" != "TRUE" ]
    then
            MIN_DATE=$(echo $3 | ${AWK} '{ print $1, $2, $4 }')
            printf "%-1s %-1s %-1s %-1s %-1s\n" "$1" "$5" "$2" "$MIN_DATE" "$4"
    fi
}

##########################################
# Purpose: Describe how the script works
# Arguments:
#   None
##########################################
usage()
{
        echo "Usage: $0 [ -e email ] [ -x expir_days ] [ -q ] [ -a ] [ -h ]"
        echo "          {[ -d domain_namee ]} || { -f domainfile}"
        echo ""
        echo "  -a               : Send a warning message through email "
        echo "  -d domain        : Domain to analyze (interactive mode)"
        echo "  -e email address : Email address to send expiration notices"
        echo "  -f domain file   : File with a list of domains"
        echo "  -h               : Print this screen"
        echo "  -s whois server  : Whois sever to query for information"
        echo "  -q               : Don't print anything on the console"
        echo "  -x days          : Domain expiration interval (eg. if domain_date < days)"
        echo ""
}

### Evaluate the options passed on the command line
while getopts ae:f:hd:s:qx: option
do
        case "${option}"
        in
                a) ALARM="TRUE";;
                e) ADMIN=${OPTARG};;
                d) DOMAIN=${OPTARG};;
                f) SERVERFILE=$OPTARG;;
                s) WHOIS_SERVER=$OPTARG;;
                q) QUIET="TRUE";;
                x) WARNDAYS=$OPTARG;;
                \?) usage
                    exit 1;;
        esac
done

### Check to see if the whois binary exists
if [ ! -f ${WHOIS} ]
then
        echo "ERROR: The whois binary does not exist in ${WHOIS} ."
        echo "  FIX: Please modify the \$WHOIS variable in the program header."
        exit 1
fi

### Check to make sure a date utility is available
if [ ! -f ${DATE} ]
then
        echo "ERROR: The date binary does not exist in ${DATE} ."
        echo "  FIX: Please modify the \$DATE variable in the program header."
        exit 1
fi

### Baseline the dates so we have something to compare to
MONTH=$(${DATE} "+%m")
DAY=$(${DATE} "+%d")
YEAR=$(${DATE} "+%Y")
NOWJULIAN=$(date2julian ${MONTH#0} ${DAY#0} ${YEAR})

### Touch the files prior to using them
touch ${WHOIS_TMP}

### If a HOST and PORT were passed on the cmdline, use those values
if [ "${DOMAIN}" != "" ]
then
        print_heading
        check_domain_status "${DOMAIN}"
### If a file and a "-a" are passed on the command line, check all
### of the domains in the file to see if they are about to expire
elif [ -f "${SERVERFILE}" ]
then
        echo -e "\n$(date)" >> $logPath/domain-check.log
        print_heading | tee -a $logPath/domain-check.log
        if [ -e "$logPath/domain-results" ];then
                rm $logPath/domain-results
        fi

        while read DOMAIN
        do
                check_domain_status "${DOMAIN}"

        done < ${SERVERFILE}

	if [ "${ALARM}" = "TRUE" ];then
	        if [ -s "$logPath/domain-results" ];then
        	        NONGAMING=`ls "${SERVERFILE}"| awk '/non/'`
                	if [ "$NONGAMING" ];then
                        	cat $logPath/domain-results \
	                        | ${MAIL} -r "domaincheck@lazybugstudio.com (Domain Check)" -s "Those Non-Gaming Domains will expire in ${WARNDAYS}-days or less" "${ADMIN}"
        	        else
                	        cat $logPath/domain-results \
                        	| ${MAIL} -r "domaincheck@lazybugstudio.com (Domain Check)" -s "Those Gaming Domains will expire in ${WARNDAYS}-days or less" "${ADMIN}"
	                fi
        	fi
	fi

### There was an error, so print a detailed usage message and exit
else
        usage
        exit 1
fi

# Add an extra newline
echo

### Remove the temporary files
rm -f ${WHOIS_TMP}

### Exit with a success indicator
exit 0


