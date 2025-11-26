#!/usr/bin/env bash

echo -ne "What is the FQDN is hosted on? \e[38;5;208m"
read FQDN
echo -e "\e[0m" 
if [[ -z "$FQDN" ]]; then exit 1; fi

echo -ne "What is the default gateway of your local network (WiFi)? \e[38;5;208m"
read WIFI_GATEWAY
echo -e "\e[0m" 
if [[ -z "$WIFI_GATEWAY" ]]; then WIFI_GATEWAY="foo"; fi

echo -ne "What is the default gateway (Ethernet)? \e[38;5;208m"
read ETH_GATEWAY
echo -e "\e[0m" 
if [[ -z "$ETH_GATEWAY" ]]; then ETH_GATEWAY="foo"; fi


cp intune-actuator.in.ps1 intune-actuator.ps1
sed -i "s/{{SERVICE_FQDN}}/$FQDN/g" intune-actuator.ps1
sed -i "s/{{WIFI_GATEWAY}}/$WIFI_GATEWAY/g" intune-actuator.ps1
sed -i "s/{{ETH_GATEWAY}}/$ETH_GATEWAY/g" intune-actuator.ps1

