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
        # This one's more for information, really. Not used directly
        # in the restore.
        docker exec radarr_radarr_1 sqlite3 /config/radarr.db .dump > /data/radarr.sql
        # Stop the app to guarantee coherency
        docker stop radarr_radarr_1
        # These two files are the only ones that Radarr backs up itself
        docker cp radarr_radarr_1:/config/config.xml /data/config.xml
        docker cp radarr_radarr_1:/config/radarr.db /data/radarr.db
    elif [ "$OPERATIONNAME" == "Restore" ]
    then
        # Delete all db files as per documentation
        docker exec radarr_radarr_1 rm -f /config/radarr.db /config/radarr.db-shm /config/radarr.db-wal
        # Stop the app to guarantee coherency
        docker stop radarr_radarr_1
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a backup, clean up the files we made
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        docker start radarr_radarr_1
        rm -f /data/config.xml
        rm -f /data/radarr.db
        rm -f /data/radarr.sql
    # If we're being run after a restore, inject the restored files
    # and reinstate them
    elif [ "$OPERATIONNAME" == "Restore" ]
    then
        # Reinstate the files and start the app once more
        docker cp /data/config.xml radarr_radarr_1:/config/config.xml
        docker cp /data/radarr.db radarr_radarr_1:/config/radarr.db
        docker cp /data/radarr.sql radarr_radarr_1:/config/radarr.sql
        docker start radarr_radarr_1
        rm -f /data/config.xml
        rm -f /data/radarr.db
        rm -f /data/radarr.sql
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
