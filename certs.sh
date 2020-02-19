#!/bin/bash
# Copy certs from le.soh.re vm to here
if [ "$#" -ne 1 ];then
    echo "This script takes 1 argument"
    echo "Domain"
    echo "./certs.sh jmainguy.com"
    exit 1
fi

DOMAIN=$1
/etc/ssl/private/letsencrypt/check_ssl.py ${DOMAIN}
rc=$?
if [ ${rc}  == 2 ]; then
    echo "cant even check the SSL cert"
    exit 1
elif [ ${rc} == 0 ]; then
    echo "Cert does not need an udate"
    exit 0
fi
# Backup working haproxy.cfg
bak /etc/haproxy/haproxy.cfg  -f

# Change web host LetsEncrypt server
cp /etc/ssl/private/letsencrypt/haproxy.cfg /etc/haproxy/haproxy.cfg
systemctl restart haproxy

# Create certs
if [ $DOMAIN == 'standouthost.com' ]; then
    ssh le.soh.re "/usr/src/letsencrypt/letsencrypt-auto --text --email jon@soh.re --domains ${DOMAIN},www.${DOMAIN} --agree-tos --renew-by-default --webroot -w /var/www/html certonly"
else
    ssh le.soh.re "/usr/src/letsencrypt/letsencrypt-auto --text --email jon@soh.re --domains ${DOMAIN} --agree-tos --renew-by-default --webroot -w /var/www/html certonly"
fi

# Copy certs to haproxy location
if [ ! -d ${DOMAIN} ]; then
    mkdir ${DOMAIN}
fi
scp root@le.soh.re:/etc/letsencrypt/live/${DOMAIN}/* ${DOMAIN}/
cat ${DOMAIN}/fullchain.pem > ${DOMAIN}/${DOMAIN}.pem
cat ${DOMAIN}/privkey.pem >> ${DOMAIN}/${DOMAIN}.pem
cp ${DOMAIN}/${DOMAIN}.pem /etc/ssl/private/

# Change back to original web server
unbak /etc/haproxy/haproxy.cfg.bak
systemctl restart haproxy
