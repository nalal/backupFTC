#!/bin/bash

#Lets check these at the very start
if [ ! -n "$BASH" ]; then
    echo Please run this script $0 with bash
    exit 1
fi

##
# Common Message Responces
##
Log_Prefix="[Log]"
Debug_Prefix="[Debug]"
Error_Prefix="[Error]"
Warn_Prefix="[Warn]"

if ! [ -x "$(command -v jq)" ] || ! [ -x "$(command -v curl)" ]; then
    sudo apt-get install -y jq curl || echo "$Error_Prefix apt-get failed to install requirements. Stopping..." && exit
fi

###
# Variable Setup
###

Discord_Enable="$(cat config.json | jq '.discord.enabled')"
Discord_Webhook="$(cat config.json | jq '.discord.webhook')"
SSH_Username=$(cat config.json | jq --raw-output '.ssh.username')
SSH_Host="$(cat config.json | jq --raw-output '.ssh.host')"
SSH_Port="$(cat config.json | jq '.ssh.port')"
SSH_Key="$(cat config.json | jq --raw-output '.ssh.ssh_key')"
Remote_Hostname="$(cat config.json | jq --raw-output '.remote.expected_hostname')"

function Sanity_Check() {
    #Check if Discord is enabled and configured correctly

    if [ "$Discord_isEnabled" = true ]; then
        if [ -z "$Discord_Webhook" ]; then
            discord_enable=$true
            local msg="$Log_Prefix Discord Webhook is enabled"
            echo "Webhook is $Discord_Webhook"
        else
            discord_enable=$false
            local msg="$Error_Prefix Discord webhook cannot be blank! \n"
            local msg="$msg$Log_Prefix Discord webhook is Disabled"
            echo -e $msg
        fi
    fi

    # Check if we can SSH

    local CheckSSH=$(ssh -p $SSH_Port -i $SSH_Key $SSH_Username@$SSH_Host hostname)
    if [ "${CheckSSH}" == "${Remote_Hostname}" ]; then
        local msg="$Log_Prefix We can connect via SSH!"
        echo $msg
    else
        local msg="$Error_Prefix Expected $Remote_Hostname but was returned $CheckSSH"
        echo $msg
        exit 1
    fi
}
function Discord_SendWebhookMsg() {
    # Requires Arguements: 2
    # $1 Should we mention @Administrator?
    # $2 Should return the message
    # Example: Discord_SendWebhookMsg "yes" "[19/04/2019]@[10:47]Backup failed."
    if [ $# -ne 2 ]; then
        echo 1>&2 "Usage: Discord_SendWebhookMsg() NotifyAdmins(boolean) Message(string)"
        exit 1
    fi
    NotifyAdmin="${echo $1 | tr '[:upper:]' '[:lower:]'}"
    if [ $NotifyAdmin == "true" ] || [ $NotifyAdmin == "yes" ]; then
        local message=""
        curl -H "Content-Type: application/json" \
        -X POST \
        -d '{"username": "Backup Script", "content": "hello"}' $url
    fi
}

Sanity_Check
