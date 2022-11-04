#!/bin/bash

#script per la gestione apache server installazione; rimozione; clean e backup configurazione iniziale; backup configurazione corrente e ripristino configurazione originale



case $1 in
# Installa httpd
    install)
        yum install -y httpd httpd-manual mod_ssl mod_php
        systemctl start httpd.service
        ;;
# Rimuove httpd e i suoi file di configurazione
    uninstall)
        yum remove -y httpd httpd-manual mod_ssh mod_php
        rm -rf /etc/httpd
        ;;
# Rimozione httpd pulizia dei file di confiugurazione, installazione e backup di una versione pulita dei file di config
    clean)
        yum remove -y httpd &>/dev/null
        rm -rf /etc/httpd
        yum -y install httpd &>/dev/null
        cp -Rp /etc/httpd /etc/httpd_ORIGIN
        ;;
    backup)
#backup configurazione attuale e ripristino configurazione di default httpd
        systemctl stop httpd.service 
        cp -Rp /etc/httpd /etc/httpd$(date +%y%m%d%H%M%S)
        rm -rf /etc/httpd
        cp -RP /etc/httpd_ORIGIN /etc/httpd
        systemctl start httpd.service 
        ;;
    *)
        echo usage "$0 <install|clean|backup>"
        exit 1
esac
