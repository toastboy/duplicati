#!/bin/bash

# Based on this example:
# https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Modules/Builtin/run-script-example.sh

# We read a few variables first.
EVENTNAME=$DUPLICATI__EVENTNAME
OPERATIONNAME=$DUPLICATI__OPERATIONNAME
REMOTEURL=$DUPLICATI__REMOTEURL
LOCALPATH=$DUPLICATI__LOCALPATH

# Make sure our backup location exists
BACKUPDIR=/backups/sabnzbd
mkdir -p $BACKUPDIR

# Basic setup, we use the same file for both before and after,
# so we need to figure out which event has happened
if [ "$EVENTNAME" == "BEFORE" ]
then

    # If we're being run before a backup, extract the files we need
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        # Stop the app to guarantee coherency
        docker stop sabnzbd
        # There's only 1 file that needs backing up according to:
        # https://forums.sabnzbd.org/viewtopic.php?t=24102
        docker cp sabnzbd:/config/sabnzbd.ini $BACKUPDIR/sabnzbd.ini
        docker start sabnzbd
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a restore, install the files into the container
    if [ "$OPERATIONNAME" == "Restore" ]
    then
        # Stop the app to guarantee coherency
        docker stop sabnzbd
        # Reinstate the files and start the app once more, making sure
        # we get file ownership and permissions right
        docker cp $BACKUPDIR/sabnzbd.ini sabnzbd:/config/sabnzbd.ini
        docker start sabnzbd
        docker exec sabnzbd chown abc:abc /config/sabnzbd.ini
        docker exec sabnzbd chmod 600 /config/sabnzbd.ini
        docker restart sabnzbd
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
