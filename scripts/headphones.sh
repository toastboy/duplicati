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
        docker stop headphones
        # These two files are the only ones that Headphones backs up itself
        docker cp headphones:/config/config.ini /data/config.ini
        docker cp headphones:/config/headphones.db /data/headphones.db
        # This one's more for information, really. Not used directly
        # in the restore. Doing the dump in the duplicati context
        # because headphones doesn't have sqlite installed (presumably
        # does everything via the python lib)
        sqlite3 /data/headphones.db .dump > /data/headphones.sql
    elif [ "$OPERATIONNAME" == "Restore" ]
    then
        # Delete all db files as per documentation
        docker exec headphones rm -f /config/headphones.db /config/headphones.db-shm /config/headphones.db-wal
        # Stop the app to guarantee coherency
        docker stop headphones
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a backup, clean up the files we made
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        docker start headphones
        rm -f /data/config.ini
        rm -f /data/headphones.db
        rm -f /data/headphones.sql
    # If we're being run after a restore, inject the restored files
    # and reinstate them
    elif [ "$OPERATIONNAME" == "Restore" ]
    then
        # Reinstate the files and start the app once more
        docker cp /data/config.ini headphones:/config/config.ini
        docker cp /data/headphones.db headphones:/config/headphones.db
        docker cp /data/headphones.sql headphones:/config/headphones.sql
        docker start headphones
        rm -f /data/config.ini
        rm -f /data/headphones.db
        rm -f /data/headphones.sql
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
