#!/bin/bash

source .variables

TOKEN=$1 #152 characters
TYPE=$2 #VoWiFi

## Check for valid variables file
if [ ! -f .variables ]; then
    echo "No .variables file defined."
    exit 1
else
    source .variables
fi

## Check for valid token
if [ -z ${TOKEN} ]; then
    echo "Invalid token. Usage ./fcm.sh <TOKEN> <VoWiFi>"
    exit 1
elif [[ ${TOKEN} =~ ^[a-zA-Z0-9\:\_\-]{152}$ ]]; then
	#Valid token
	TOKEN=${TOKEN}
else
    echo "Invalid token. Usage ./fcm.sh <TOKEN> <VoWiFi>"
    exit 1
fi

## Check for valid service
if [ -z ${TYPE} ]; then
    echo "Invalid service. Usage ./fcm.sh <TOKEN> <VoWiFi>"
    exit 1
elif [ ${TYPE} == "VoWiFi" ]; then
	APP=ap2004
else
    echo "Invalid service. Usage ./fcm.sh <TOKEN> <VoWiFi>"
    exit 1
fi

## Assign variables
DATE=$(date --iso-8601=seconds)

## Execute push
curl --silent -X POST --header "Authorization: key=${FCM_SERVER_KEY}" \
    --Header "Content-Type: application/json" \
    https://fcm.googleapis.com/fcm/send \
	-d '{"data":{"app":"ap2004","timestamp":"'${DATE}'"},"priority": "high","time_to_live":2419200,"to":"'${TOKEN}'"}' | jq
