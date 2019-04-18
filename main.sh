#!/bin/bash

###
# Variable Setup
###
discord_enable=$false
discord_webhook=""
ssh_username=""
ssh_host=""
ssh_port=""

##
# Common Message Responces
##
Log_Prefix="[Log]"
Debug_Prefix="[Debug]"
Error_Prefix="[Error]"
Warn_Prefix="[Warn]"

# This is coded to require Bash, sh Is not a valid shell!
if [ ! -n "$BASH" ]; then
    echo Please run this script $0 with bash
    exit 1
fi

function Sanity_Check() {
    #lets make sure we have the packages we need
    if ! [ -x "$(command -v jq)" ]; then
        if [ $1 = "--force-install"]; then
            echo "$Warn_Prefix Force install enabled!"
            pkg install -y jq
        else
            echo 'Error: jq is not installed.' >&2
            exit 1
        fi
    fi
    if ! [ -x "$(command -v curl)" ]; then
        if [ $1 = "--force-install"]; then
            echo "$Warn_Prefix Force install enabled!"
            pkg install -y curl
        else
            echo 'Error: curl is not installed.' >&2
            exit 1
        fi
    fi

    #Check if Discord is enabled and configured correctly
    local Discord_isEnabled="$(cat config.json | jq '.discord.enabled')"
    local Discord_Webhook="$(cat config.json | jq '.discord.webhook')"

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
    local SSH_Username=$(cat config.json | jq --raw-output '.ssh.username')
    local SSH_Host="$(cat config.json | jq --raw-output '.ssh.host')"
    local SSH_Port="$(cat config.json | jq '.ssh.port')"
    local SSH_Key="$(cat config.json | jq --raw-output '.ssh.ssh_key')"
    local Remote_Hostname="$(cat config.json | jq --raw-output '.remote.expected_hostname')"

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
    # Example: Discord_SendWebhookMsg "Yes" "[19/04/2019]@[10:47]Backup failed." 
    if [ $# -ne 2 ]; then
        echo 1>&2 "Usage: Discord_SendWebhookMsg() NotifyAdmins(boolean) Message(string)"
        exit 1
    fi
}

Sanity_Check
