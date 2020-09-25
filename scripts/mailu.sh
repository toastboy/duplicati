#!/bin/bash

# Based on this example:
# https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Modules/Builtin/run-script-example.sh

# We read a few variables first.
EVENTNAME=$DUPLICATI__EVENTNAME
OPERATIONNAME=$DUPLICATI__OPERATIONNAME
REMOTEURL=$DUPLICATI__REMOTEURL
LOCALPATH=$DUPLICATI__LOCALPATH

# Make sure our backup location exists
BACKUPDIR=/backups/mail
mkdir -p $BACKUPDIR

# Stop the app to guarantee coherency
function app_stop {
    docker stop mail-admin
    docker stop mail-antispam
    docker stop mail-antivirus
    docker stop mail-fetchmail
    docker stop mail
    docker stop mail-imap
    docker stop mail-redis
    docker stop mail-resolver
    docker stop mail-smtp
    docker stop mail-webdav
    docker stop mail-webmail
}

# Start the app once more
function app_start {
    docker start mail-admin
    docker start mail-antispam
    docker start mail-antivirus
    docker start mail-fetchmail
    docker start mail
    docker start mail-imap
    docker start mail-redis
    docker start mail-resolver
    docker start mail-smtp
    docker start mail-webdav
    docker start mail-webmail
}

# Basic setup, we use the same file for both before and after,
# so we need to figure out which event has happened
if [ "$EVENTNAME" == "BEFORE" ]
then

    # If we're being run before a backup, extract the files we need
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        app_stop
        # Deliberately not backing up certs as they can and should be
        # regenerated
        docker exec mail-backup rsync --recursive --archive --delete --quiet --times --relative --checksum --delete-missing-args /data/ /dav/ /dkim/ /filter/ /mail/ /overrides/ /redis/ /webmail/ $BACKUPDIR
        app_start
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a restore, inject the restored files
    # and reinstate them
    if [ "$OPERATIONNAME" == "Restore" ]
    then
        app_stop
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/data/ /data/
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/dav/ /dav/
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/dkim/ /dkim/
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/filter/ /filter/
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/mail/ /mail/
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/overrides/ /overrides/
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/redis/ /redis/
        docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/webmail/ /webmail/
        app_start
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
