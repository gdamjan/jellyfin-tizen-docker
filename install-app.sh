#!/bin/bash

set -euxo pipefail

if [ -z "$1" ]
then
  echo "Usage: ./install.sh <IP-ADDRESS>"
  echo "Must specify the TV ip address."
  exit 1
fi

TV_IP=$1

sdb connect ${TV_IP}

DEVICE_ID=$(sdb devices | grep ${TV_IP} | awk '{ print $3 }')

if [ -z "$DEVICE_ID" ]
then
  echo "Device ID not found. Perhaps the TV ip address is incorrect."
  exit 1
fi

tizen install -n Jellyfin.wgt -t ${DEVICE_ID}
