#!/bin/bash

if [[ "$#" -ne 2 ]]; then
    echo "You must specify two arguments: unix-user and domain for renew certificates"
    exit 1
fi

USER=$1
DOMAIN=$2
LELIVE=/etc/letsencrypt/live
LEHOME=/root/tmp/letsencrypt

# CHeck user
if [[ ! $(cat /etc/passwd | grep $USER) ]]; then
    echo "User '$USER' not found"
    exit 1
fi

# Check domain
if [[ ! $(ls /home/$USER/conf/web/ | grep -E "^ssl.$DOMAIN") || ! $(ls $LELIVE/$DOMAIN) ]]; then
    echo "Domain '$DOMAIN' or certs for this domain not found are not found"
    exit 1
fi

for FILE_NAME in cert.pem chain.pem fullchain.pem privkey.pem; do
    REQUIRED_FILE=$LELIVE/$DOMAIN/$FILE_NAME
    if [[ ! $(ls $REQUIRED_FILE) ]]; then
        echo "Required file '$REQUIRED_FILE' not found"
        exit 1
    fi
done

# Renew
service nginx stop
cd $LEHOME
./letsencrypt-auto renew
service nginx start

# Dump new files
cat $LELIVE/$DOMAIN/chain.pem >     /home/$USER/conf/web/ssl.$DOMAIN.ca
cat $LELIVE/$DOMAIN/cert.pem >      /home/$USER/conf/web/ssl.$DOMAIN.crt
cat $LELIVE/$DOMAIN/privkey.pem >   /home/$USER/conf/web/ssl.$DOMAIN.key
cat $LELIVE/$DOMAIN/cert.pem \
    $LELIVE/$DOMAIN/chain.pem >     /home/$USER/conf/web/ssl.$DOMAIN.pem

service nginx restart
service httpd restart
