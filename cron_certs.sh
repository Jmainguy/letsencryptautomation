#!/bin/bash
space ()
{ # Print spaces
    echo ""
    echo ""
}
# Bak up /etc/hosts so we can check the real connection
bak /etc/hosts -f
cp /etc/ssl/private/letsencrypt/hosts /etc/hosts
for DOMAIN in $(cat /etc/ssl/private/letsencrypt/hostnames); do
    echo ${DOMAIN}
    /etc/ssl/private/letsencrypt/lets_certs.py ${DOMAIN}
    space
done
unbak /etc/hosts.bak
