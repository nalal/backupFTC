#!/bin/bash
#
# NOTE THIS IS A PROOF OF CONCEPT ONLY
#
# The commented section below should be provided via enviroment variables however
# this part may changed to support a docker enviroment, meaning we dont want/need to check the git repo consistantly
# and instead want something to keep the docker image updated on the host.
#
##########################
# git_repo="nalal/backupFTC"
# git_branch="flutters_develop"
# git_file="main.sh"
# git_hub_url="github.com/$git_repo"
# git_url="$git_hub_url/$git_file"
# git_raw_url="https://raw.githubusercontent.com/$git_repo/$git_branch/$git_file"
##################################

local_file=$(md5sum main.sh | awk '{ print $1 }')
remote_file=$(curl --silent $git_raw_url | md5sum | awk '{ print $1 }')
if [ $local_file == $remote_file ]; then
    echo "Already using latest, no need to update"
    echo "Starting main script."
    ./main.sh
else
    echo "Not running latest version of the script, Updating"
    echo "url was $git_raw_url"
    echo -e "Remote MD5 is $remote_file \nLocal MD5 is $local_file"
    echo $git_raw_url
    # This is not a "clean" nor safe way to do it, however this is also the safest way i can think of
    git reset --hard origin/$git_branch
fi
