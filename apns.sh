#!/bin/bash
TOKEN=$1 #As Base64 or HEX
TYPE=$2 #VoLTE or VoWiFi


## Check for valid variables file
if [ ! -f .variables ]; then
	echo "No .variables file defined."
	exit 1
else
	source .variables
fi

## Check for valid token
if [ -z ${TOKEN} ]; then
	echo "Invalid token. Usage ./apns.sh <TOKEN> <VoLTE|VoWiFi>"
	exit 1
elif [[ ${TOKEN} =~ ^[a-zA-Z0-9\/\+]{43}=$ ]]; then
	#Token is Base64, convert to HEX
	TOKEN=$(echo -n "${TOKEN}" | base64 -d -i | hexdump -v -e '/1 "%02x" ' | tr '[:lower:]' '[:upper:]')
elif [[ ${TOKEN} =~ ^[a-fA-F0-9]{64}$ ]]; then
	#Token is HEX
	TOKEN=${TOKEN}
else
	echo "Invalid token. Usage ./apns.sh <TOKEN> <VoLTE|VoWiFi>"
	exit 1
fi

## Check for valid service
if [ -z ${TYPE} ]; then
	echo "Invalid service. Usage ./apns.sh <TOKEN> <VoLTE|VoWiFi>"
	exit 1
elif [ ${TYPE} == "VoLTE" ]; then
	TOPIC=${VOLTE_TOPIC}
	TRIGGER=entitlements-changed
	CERT=volte.pem
elif [ ${TYPE} == "VoWiFi" ]; then
	TOPIC=${VOWIFI_TOPIC}
	TRIGGER=provisioning-changed
	CERT=vowifi.pem
else
	echo "Invalid service. Usage ./apns.sh <TOKEN> <VoLTE|VoWiFi>"
	exit 1
fi

## Check for valid topic
if [ -z ${TOPIC} ] ; then
	echo "Invalid topic. Please populate .variables file"
	exit 1
fi

## Check for valid certificate
if [ ! -f ${CERT} ]; then
	echo "${CERT} does not exist."
	exit 1
fi

## Assign variables
DATE=$(date --iso-8601=seconds)

## Execute push
curl -v --tlsv1.2 \
-d '{"entitlement-update":{"timestamp":"'${DATE}'","trigger-actions":["'${TRIGGER}'"],}}' \
-H "apns-topic: ${TOPIC}" \
-H "apns-priority: 10" \
--http2 \
--cert ${CERT} \
https://api.push.apple.com/3/device/${TOKEN}
