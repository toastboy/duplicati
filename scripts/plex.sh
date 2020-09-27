#!/bin/bash

# Based on this example:
# https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Modules/Builtin/run-script-example.sh

# We read a few variables first.
EVENTNAME=$DUPLICATI__EVENTNAME
OPERATIONNAME=$DUPLICATI__OPERATIONNAME
REMOTEURL=$DUPLICATI__REMOTEURL
LOCALPATH=$DUPLICATI__LOCALPATH

# Make sure our backup location exists
BACKUPDIR=/backups/plex
mkdir -p $BACKUPDIR

# Basic setup, we use the same file for both before and after,
# so we need to figure out which event has happened
if [ "$EVENTNAME" == "BEFORE" ]
then

    # If we're being run before a backup, extract the files we need
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        # These are more for information, really. Not used directly in
        # the restore.
        docker exec plex-backup sqlite3 "/mnt/affordance_usb/Android/data/com.plexapp.mediaserver.smb/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db" .dump | gzip > $BACKUPDIR/com.plexapp.plugins.library.db.sql.gz
        docker exec plex-backup sqlite3 "/mnt/affordance_usb/Android/data/com.plexapp.mediaserver.smb/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.blobs.db" .dump | gzip > $BACKUPDIR/com.plexapp.plugins.library.blobs.db.sql.gz
        docker exec plex-backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args "/mnt/affordance_internal/Plex Media Server/Database Backups/" "$BACKUPDIR/Database Backups/"
        docker cp plex-backup:"/mnt/affordance_usb/Android/data/com.plexapp.mediaserver.smb/Plex Media Server/Preferences.xml" $BACKUPDIR/Preferences.xml
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a restore, install the files into the
    # container: IN THIS CASE SOME MANUAL FERNAGLING WITH THE PLEX
    # MEDIA SERVER SHUT DOWN ON THE SHIELD TV PRO IS NECESSARY
    if [ "$OPERATIONNAME" == "Restore" ]
    then
        docker exec plex-backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args "$BACKUPDIR/Database Backups/" "/mnt/affordance_usb/Android/data/com.plexapp.mediaserver.smb/Plex Media Server/Plug-in Support/Databases/Restored Backups/"
        docker cp $BACKUPDIR/Preferences.xml plex-backup:"/mnt/affordance_usb/Android/data/com.plexapp.mediaserver.smb/Plex Media Server/Preferences_restored.xml"
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
