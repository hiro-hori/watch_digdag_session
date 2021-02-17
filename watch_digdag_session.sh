#!/bin/bash

if [ -z $1 ]; then
    echo you must specify session_id
    exit 255
fi
digdag_session_request_duration=30
session_id=$1

secrets=$(security find-generic-password -s "pushover secrets" -w)
# if [ -z $secrets ]; then
#     echo cannot get pushover passwords
#     exit 255
# fi

PUSHOVER_APP_TOKEN=$(echo $secrets | jq -r .api_token)
PUSHOVER_USER_KEY=$(echo $secrets | jq -r .user_key)
while true; do
    status=$(digdag session $session_id | tee >(cat 1>&2) | awk ' $1 == "status:" {sub("\r", "", $2); print $2}')
    # echo $status
    case "$status" in
        # "running" ) echo ruuuuuuuuuuun ;;
        "error" | "success" ) curl -s \
            --form-string "token=$PUSHOVER_APP_TOKEN" \
            --form-string "user=$PUSHOVER_USER_KEY" \
            --form-string "message=digdag session $session_id finished. status: $status" \
            https://api.pushover.net/1/messages.json
            exit 0;;
        * ) :
    esac
    sleep $digdag_session_request_duration
done

