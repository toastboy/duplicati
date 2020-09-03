#!/bin/bash

# Based on this example:
# https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Modules/Builtin/run-script-example.sh

# We read a few variables first.
EVENTNAME=$DUPLICATI__EVENTNAME
OPERATIONNAME=$DUPLICATI__OPERATIONNAME
REMOTEURL=$DUPLICATI__REMOTEURL
LOCALPATH=$DUPLICATI__LOCALPATH

# Stop the app to guarantee coherency
function app_stop {
    docker stop mailu_admin_1
    docker stop mailu_antispam_1
    docker stop mailu_antivirus_1
    docker stop mailu_fetchmail_1
    docker stop mailu_front_1
    docker stop mailu_imap_1
    docker stop mailu_redis_1
    docker stop mailu_resolver_1
    docker stop mailu_smtp_1
    docker stop mailu_webdav_1
    docker stop mailu_webmail_1
}

# Start the app once more
function app_start {
    docker start mailu_admin_1
    docker start mailu_antispam_1
    docker start mailu_antivirus_1
    docker start mailu_fetchmail_1
    docker start mailu_front_1
    docker start mailu_imap_1
    docker start mailu_redis_1
    docker start mailu_resolver_1
    docker start mailu_smtp_1
    docker start mailu_webdav_1
    docker start mailu_webmail_1
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
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --relative --checksum --delete-missing-args /data/ /dav/ /dkim/ /filter/ /mail/ /overrides/ /redis/ /webmail/ /backups/mailu/
        app_start
    elif [ "$OPERATIONNAME" == "Restore" ]
    then
        rm -rf /backups/mailu/*
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a restore, inject the restored files
    # and reinstate them
    if [ "$OPERATIONNAME" == "Restore" ]
    then
        app_stop
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/data/ /data/
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/dav/ /dav/
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/dkim/ /dkim/
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/filter/ /filter/
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/mail/ /mail/
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/overrides/ /overrides/
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/redis/ /redis/
        docker exec mailu_backup_1 rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /backups/mailu/webmail/ /webmail/
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
