#!/bin/bash 

#Variables from Command Line
VHOSTNAME=$1
TIER=$2

#Other variables
HTTPDCONF=/etc/httpd/conf/httpd.conf
VHOSTCONFDIR=/etc/httpd/conf.vhosts.d
DEFVHOSTCONFFILE=$VHOSTCONFDIR/00-default-vhost.conf
VHOSTCONFFILE=$VHOSTCONFDIR/$VHOSTNAME.conf
WWWROOT=/srv
DEFVHOSTDOCROOT=$WWWROOT/default/www
VHOSTDOCROOT=$WWWROOT/$VHOSTNAME/www

#Check Arguments

if ["$VHOSTNAME" -eq ''] || ["$TIER" -eq '']; then
    echo "Usage: $0 VHOSTNAME TIER"
    exit 1
else
    
    #Set support email addres

    case $TIER in

    1)  VHOSTADMIN='basic_support@example.com'
        ;;
    2)  VHOSTADMIN='business_support@example.com'
        ;;
    3)  VHOSTADMIN='enterprise_support@example.com'
        ;;
    *)  echo "Invalid tier specified"
        exit 1
        ;;
    esac
fi

#Check the existence of VHOSTCONFDIR directory
if [! -d $VHOSTCONFDIR]; then
    mkdir -p $VHOSTCONFDIR
    restorecon -Rv $VHOSTCONFDIR
fi

grep -q '^IncludeOptional conf\.vhosts\.d/\*\.conf$' $HTTPDCONF
if [ $? -ne 0 ]; then
    # Backup before modifying
    cp -a $HTTPDCONF $HTTPDCONF.orig
    echo "IncludeOptional conf.vhosts.d/*.conf" >> $HTTPDCONF
    mkdir $VHOSTCONFDIR
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed adding include directive."
        exit 1
    fi
fi

#Check if DEFVHOSTCONFFILE already exists
if [! -f $DEFVHOSTCONFFILE]; then
    cat <<DEFCONFEOF > $DEFVHOSTCONFFILE
    <VirtualHost _default_:80>
        DocumentRoot $DEFVHOSTDOCROOT
        CustomLog "logs/default-vhost.log" combined
    </VirtualHost>
    <Directory $DEFVHOSTDOCROOT>
        Require all granted
    </Directory>
    DEFCONFEOF
fi



#Check the DEFVHOSTDOCROOT
if [! -d $DEFVHOSTDOCROOT]; then
    mkdir -p $DEFVHOSTDOCROOT
    restorecon -Rv $WWWROOT
fi

if [-f $VHOSTCONFFILE]; then
    echo "ERROR: $VHOSTCONFFILE already exists"
    exit 1
elif [-d $VHOSTDOCROOT]; then
    echo "ERROR: $VHOSTDOCROOT already exists"
    exit 1
else
    cat <<CONFEOF > $VHOSTCONFFILE
    <Directory $VHOSTDOCROOT>
        Require all granted
        AllowOverride None
    </Directory>
    <VirtualHost *:80>
        DocumentRoot $VHOSTDOCROOT
        ServerName $VHOSTNAME
        ServerAdmin $VHOSTADMIN
        ErrorLog "logs/${VHOSTNAME}_error_log"
        CustomLog "logs/${VHOSTNAME}_access_log" common
    </VirtualHost>
    COFEOF

    mkdir -p $VHOSTDOCROOT
    restorecon -Rv $WWWROOT
    cat <<INDEXHTMLEOF > $VHOSTCONFFILE/index.html
        LAB - ENHANCING BASH SHELL SCRIPTS WITH CONDITIONALS AND CONTROL STRUCTURES
    INDEXHTMLEOF
    chown -R apache $WWWROOT
fi

#Check config and reload
apache configtest &> /dev/null
if [$? -eq 0]; then
    systemctl reload httpd &> /dev/null
else
    echo "ERROR.Configuration error"
    exit 1
fi
 
