#!/bin/bash

# Based on this example:
# https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Modules/Builtin/run-script-example.sh

# We read a few variables first.
EVENTNAME=$DUPLICATI__EVENTNAME
OPERATIONNAME=$DUPLICATI__OPERATIONNAME
REMOTEURL=$DUPLICATI__REMOTEURL
LOCALPATH=$DUPLICATI__LOCALPATH

# Basic setup, we use the same file for both before and after,
# so we need to figure out which event has happened
if [ "$EVENTNAME" == "BEFORE" ]
then

    # If we're being run before a backup, extract the files we need
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        # Stop the app to guarantee coherency
        docker stop pihole_pihole_1
        mkdir -p /backups/pihole/config
        mkdir -p /backups/pihole/dnsmasq
        docker exec pihole_backup_1 rsync -rtav --delete-missing-args /config/adlists.list /config/adlists.list /config/auditlog.list /config/blacklist.txt /config/regex.list /config/setupVars.conf /config/whitelist.txt /backups/pihole/config
        docker exec pihole_backup_1 rsync -rtav --delete-missing-args /dnsmasq/01-pihole.conf /backups/pihole/dnsmasq
    elif [ "$OPERATIONNAME" == "Restore" ]
    then
        # Stop the app to guarantee coherency
        docker stop pihole_pihole_1
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a restore, inject the restored files
    # and reinstate them
    if [ "$OPERATIONNAME" == "Restore" ]
    then
        # Reinstate the files and start the app once more
        docker exec pihole_backup_1 rsync -rtav --delete-missing-args /config/adlists.list /backups/pihole/config/* /config/
        docker exec pihole_backup_1 rsync -rtav --delete-missing-args /backups/pihole/dnsmasq/* /dnsmasq/
        docker start pihole_pihole_1
    fi

else
    # This should never happen, but there may be new operations
    # in new version of Duplicati
    # We write this to stderr, and it will show up as a warning in the logfile
    echo "Got unknown event \"$EVENTNAME\", ignoring" >&2
fi

# We want the exit code to always report success.
# For scripts that can abort execution, use the option
# --run-script-before-required = <filename> when running Duplicati
exit 0
