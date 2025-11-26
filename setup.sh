#!/usr/bin/env bash

cd "$(dirname "$0")"

set -e

echo "apt-get update"
sudo apt-get update &> /dev/null
echo "apt-get install -y docker.io docker-buildx docker-compose-v2 whois wamerican-small"
sudo apt-get install -y docker.io docker-buildx docker-compose-v2 whois wamerican-small &> /dev/null
echo

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

echo -ne "What DNS servers would you like to use (csv; e.g. \`1.1.1.1,8.8.8.8\`)? \e[38;5;208m"
read DNS
echo -e "\e[0m" 
if [[ -z "$DNS" ]]; then exit 1; fi

# pick a random word as the username
while true; do
    word=$(shuf -n 1 /usr/share/dict/words)
    if [[ $word =~ ^[a-zA-Z]+$ ]]; then
        break
    fi
done

WG_EASY_USERNAME="$word$(($RANDOM % 10000))"
WG_EASY_PASSWORD="$(openssl rand -base64 30)"

REGISTRATION_TOKEN="$(openssl rand -hex 30)"
REGISTRATION_HASH="$(mkpasswd --method=bcrypt "$REGISTRATION_TOKEN" --rounds 14)"

# write .env
echo "SERVICE_FQDN=$FQDN" > .env
echo >> .env
echo "LETSENCRYPT_EMAIL=$LETSENCRYPT_EMAIL" >> .env
echo >> .env
echo "WG_EASY_USERNAME=$WG_EASY_USERNAME" >> .env
echo "WG_EASY_PASSWORD='$WG_EASY_PASSWORD'" >> .env
echo >> .env
echo "REGISTRATION_HASH='$REGISTRATION_HASH'" >> .env


echo "Starting service..."
mkdir -p traefik/
touch traefik/acme.json && chmod 600 traefik/acme.json

export INIT_ENABLED="true";
export INIT_DNS="$DNS";
docker compose up -d


# inform about credentials
echo
echo "Your dashboard credentials are: ($WG_EASY_USERNAME, $WG_EASY_PASSWORD)"
echo "Do not change them, it would break the registration setup!"
echo
echo "Your registration token is $REGISTRATION_TOKEN"
echo "Your registration url is https://$FQDN/registration/issue.php?token=$REGISTRATION_TOKEN&pcname=<PC NAME>"
echo "Write it down! You will not get a second chance to look at it."

cp intune-setup.in.ps1 intune-setup.ps1
sed -i "s/{{SERVICE_FQDN}}/$FQDN/g" intune-setup.ps1
sed -i "s/{{REGISTRATION_TOKEN}}/$REGISTRATION_TOKEN/g" intune-setup.ps1


