#!/usr/bin/env bash

# !!! run `apt install docker.io docker-compose-v2` beforehand

cd "$(dirname "$0")"

set -e

echo "This is a guided setup script."
echo "CAVE: After entering your values, .env will get overwritten!"
echo

echo -ne "What is the FQDN your service will be hosted on? \e[38;5;208m"
read FQDN
echo -e "\e[0m" 
if [[ -z "$FQDN" ]]; then exit 1; fi

echo -ne "What is the email address you'd like to use for Let's Encrypt? \e[38;5;208m"
read LETSENCRYPT_EMAIL
echo -e "\e[0m" 
if [[ -z "$LETSENCRYPT_EMAIL" ]]; then exit 1; fi

INIT_PASSWORD="$(openssl rand -base64 21)"

echo "SERVICE_FQDN=$FQDN" > .env
echo "LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL" >> .env
echo "INIT_PASSWORD='$INIT_PASSWORD'" >> .env

echo "Your initial credentials are: (admin, $INIT_PASSWORD)"
echo "Write it down! You will not get a second chance to look at it."

mkdir -p traefik/
touch traefik/acme.json && chmod 600 traefik/acme.json

echo
echo -e "To start your service, run \e[1mdocker compose up -d\e[0m"

