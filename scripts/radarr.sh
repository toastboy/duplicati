#!/bin/bash

# Based on this example:
# https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Modules/Builtin/run-script-example.sh

# We read a few variables first.
EVENTNAME=$DUPLICATI__EVENTNAME
OPERATIONNAME=$DUPLICATI__OPERATIONNAME
REMOTEURL=$DUPLICATI__REMOTEURL
LOCALPATH=$DUPLICATI__LOCALPATH

# Make sure our backup location exists
BACKUPDIR=/backups/radarr
mkdir -p $BACKUPDIR

# Basic setup, we use the same file for both before and after,
# so we need to figure out which event has happened
if [ "$EVENTNAME" == "BEFORE" ]
then

    # If we're being run before a backup, extract the files we need
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        # This one's more for information, really. Not used directly
        # in the restore.
        docker exec radarr sqlite3 /config/radarr.db .dump > $BACKUPDIR/radarr.sql
        # Stop the app to guarantee coherency
        docker stop radarr
        # These two files are the only ones that Radarr backs up itself
        docker cp radarr:/config/config.xml $BACKUPDIR/config.xml
        docker cp radarr:/config/radarr.db $BACKUPDIR/radarr.db
        docker start radarr
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a restore, install the files into the container
    if [ "$OPERATIONNAME" == "Restore" ]
    then
        # Delete all db files as per documentation
        docker exec radarr rm -f /config/radarr.db /config/radarr.db-shm /config/radarr.db-wal
        # Stop the app to guarantee coherency
        docker stop radarr
        # Reinstate the files and start the app once more
        docker cp $BACKUPDIR/config.xml radarr:/config/config.xml
        docker cp $BACKUPDIR/radarr.db radarr:/config/radarr.db
        docker cp $BACKUPDIR/radarr.sql radarr:/config/radarr.sql
        docker start radarr
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
