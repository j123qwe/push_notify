#!/bin/bash

## Functions
check_packages(){     
    DISTRO=$(cat /etc/*-release | grep ID_LIKE | cut -d= -f2)
    if [[ ${DISTRO} =~ "debian" ]]; then
        debian_package_install
    elif [[ ${DISTRO} =~ "rhel" ]]; then
        #rhel_package_install
        echo "Not yet implemented. Exiting..."
        exit
    else
        echo "This utility will only work with Debian or RHEL based Linux system. Exiting..."
        exit
    fi
}

debian_package_install(){
    PACKAGES="jq curl"
    TOINSTALL=()
    for PKG in ${PACKAGES[@]}; do
        dpkg -s ${PKG} &> /dev/null
        if [ $? -eq 1 ]; then
            TOINSTALL+=("${PKG}")
        elif [ $? -gt 1 ]; then
            echo "Potential problem with ${PKG}. Please investigate. Exiting..."
            exit
        fi
    done
    if [[ ! -z ${TOINSTALL[@]} ]]; then
            sudo apt install -y "${TOINSTALL[@]}"
    fi
}

check_apns_token(){
if [ -z ${TOKEN} ]; then
	echo "Invalid token. Usage ./push.sh apns <TOKEN> <VoLTE|VoWiFi>"
	exit 1
elif [[ ${TOKEN} =~ ^[a-zA-Z0-9\/\+]{43}=$ ]]; then
	#Token is Base64, convert to HEX
	TOKEN=$(echo -n "${TOKEN}" | base64 -d -i | hexdump -v -e '/1 "%02x" ' | tr '[:lower:]' '[:upper:]')
elif [[ ${TOKEN} =~ ^[a-fA-F0-9]{64}$ ]]; then
	#Token is HEX
	TOKEN=${TOKEN}
else
	echo "Invalid token. Usage ./push.sh apns <TOKEN> <VoLTE|VoWiFi>"
	exit 1
fi
}

check_fcm_token(){
if [ -z ${TOKEN} ]; then
    echo "Invalid token. Usage ./push.sh fcm <TOKEN> <VoWiFi>"
    exit 1
elif [[ ${TOKEN} =~ ^[a-zA-Z0-9\:\_\-]{152}$ ]]; then
	#Valid token
	TOKEN=${TOKEN}
else
    echo "Invalid token. Usage ./push.sh fcm <TOKEN> <VoWiFi>"
    exit 1
fi
}

check_apns_topic(){
## Check for valid topic
if [ -z ${TOPIC} ] ; then
	echo "Invalid topic. Please populate .variables file"
	exit 1
fi
}

check_apns_cert(){
## Check for valid certificate
if [ ! -f ${CERT} ]; then
	echo "${CERT} does not exist."
	exit 1
fi
}

check_fcm_server_key(){
## Check for valid FCM server key
if [ -z ${FCM_SERVER_KEY} ]; then
    echo "Invalid FCM server key defined in .variables"
    exit 1
fi
}

push_apns(){
curl -v --tlsv1.2 \
-d '{"entitlement-update":{"timestamp":"'${DATE}'","trigger-actions":["'${TRIGGER}'"],}}' \
-H "apns-topic: ${TOPIC}" \
-H "apns-priority: 10" \
--http2 \
--cert ${CERT} \
https://api.push.apple.com/3/device/${TOKEN}
}

push_fcm(){
curl --silent -X POST --header "Authorization: key=${FCM_SERVER_KEY}" \
    --Header "Content-Type: application/json" \
    https://fcm.googleapis.com/fcm/send \
	-d '{"data":{"app":"ap2004","timestamp":"'${DATE}'"},"priority": "high","time_to_live":2419200,"to":"'${TOKEN}'"}' | jq
}

## Execution
check_packages

SERVICE=$1 #apns or fcm
TOKEN=$2 #Base64 or HEX for APNS, 152 char for FCM
TYPE=$3 #VoLTE or VoWiFi

## Check for valid variables file
if [ ! -f .variables ]; then
	echo "No .variables file defined."
	exit 1
else
	source .variables
fi

## Check for valid service
if [ -z ${TYPE} ]; then
    echo "Invalid service. Usage ./push.sh <apns|fcm> <TOKEN> <VoLTE|VoWiFi>"
    exit 1
elif [ ${TYPE} == "VoLTE" ]; then
    TOPIC=${VOLTE_TOPIC}
	TRIGGER=entitlements-changed
	CERT=volte.pem
elif [ ${TYPE} == "VoWiFi" ]; then
	APP=ap2004
    TOPIC=${VOWIFI_TOPIC}
	TRIGGER=provisioning-changed
	CERT=vowifi.pem
else
    echo "Invalid service. Usage ./push.sh <apns|fcm> <VoLTE|VoWiFi>"
    exit 1
fi

## Assign variables
DATE=$(date --iso-8601=seconds)

## Execute service 
if [ ${SERVICE} == "apns" ]; then
    check_apns_token
    check_apns_topic
    check_apns_cert
    push_apns
elif [ ${SERVICE} == "fcm" ]; then
    check_fcm_token
    check_fcm_server_key
    push_fcm
else
    echo "Invalid service."
    exit 0
fi