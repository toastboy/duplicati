#!/bin/bash

# Based on this example:
# https://github.com/duplicati/duplicati/blob/master/Duplicati/Library/Modules/Builtin/run-script-example.sh

# We read a few variables first.
BACKUPNAME=$DUPLICATI__backup_name
EVENTNAME=$DUPLICATI__EVENTNAME
OPERATIONNAME=$DUPLICATI__OPERATIONNAME
REMOTEURL=$DUPLICATI__REMOTEURL
LOCALPATH=$DUPLICATI__LOCALPATH

# Make sure our backup location exists
BACKUPDIR=/backups/$BACKUPNAME
mkdir -p $BACKUPDIR

function app_stop {
    case "$BACKUPNAME" in

        "headphones")
            docker stop headphones
            ;;

        "jackett")
            docker stop jackett
            ;;

        "jenkins")
            docker stop jenkins
            ;;

        "lidarr")
            docker stop lidarr
            ;;

        "mailu")
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
            ;;

        "pihole")
            docker stop pihole
            ;;

        "radarr")
            docker stop radarr
            ;;

        "sabnzbd")
            docker stop sabnzbd
            ;;

        "sonarr")
            docker stop sonarr
            ;;

        "syncthing")
            docker stop syncthing
            ;;

        "transmission")
            docker stop transmission
            ;;

        "unifi-video")
            docker stop unifi-video
            ;;

        *)
            echo "Unrecognised backup name in app_stop"
            ;;
    esac
}

function app_start {
    case "$BACKUPNAME" in

        "headphones")
            docker start headphones
            ;;

        "jackett")
            docker start jackett
            ;;

        "jenkins")
            docker start jenkins
            ;;

        "lidarr")
            docker start lidarr
            ;;

        "mailu")
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
            ;;

        "pihole")
            docker start pihole
            ;;

        "radarr")
            docker start radarr
            ;;

        "sabnzbd")
            docker start sabnzbd
            ;;

        "sonarr")
            docker start sonarr
            ;;

        "syncthing")
            docker start syncthing
            ;;

        "transmission")
            docker start transmission
            ;;

        "unifi-video")
            docker start unifi-video
            ;;

        *)
            echo "Unrecognised backup name in app_start"
            ;;
    esac
}

function do_pre_backup {
    case "$BACKUPNAME" in

        "lidarr")
            # This one's more for information, really. Not used directly
            # in the restore.
            docker exec lidarr sqlite3 /config/lidarr.db .dump > $BACKUPDIR/lidarr.sql
            ;;

        "radarr")
            # This one's more for information, really. Not used directly
            # in the restore.
            docker exec radarr sqlite3 /config/radarr.db .dump > $BACKUPDIR/radarr.sql
            ;;

        "sonarr")
            # This one's more for information, really. Not used directly
            # in the restore.
            docker exec sonarr sqlite3 /config/sonarr.db .dump > $BACKUPDIR/sonarr.sql
            ;;

        *)
            ;;
    esac
}

function do_backup {
    case "$BACKUPNAME" in

        "headphones")
            # These two files are the only ones that Headphones backs up itself
            docker cp headphones:/config/config.ini $BACKUPDIR/config.ini
            docker cp headphones:/config/headphones.db $BACKUPDIR/headphones.db
            # This one's more for information, really. Not used directly
            # in the restore. Doing the dump in the duplicati context
            # because headphones doesn't have sqlite installed (presumably
            # does everything via the python lib)
            sqlite3 $BACKUPDIR/headphones.db .dump > $BACKUPDIR/headphones.sql
            ;;

        "jackett")
            docker exec jackett-backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /config/ /backups/jackett/
            ;;

        "jenkins")
            docker exec jenkins-backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args --exclude "plugins" --exclude "war" --exclude "workspace" --exclude "identity.key.enc" /var/jenkins_home/ /backups/jenkins/
            ;;

        "lidarr")
            # This is different to radarr and sonarr because I want to back up
            # the multi-GiB caches too, for convenience
            docker exec lidarr-backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args --one-file-system /config/ /backups/lidarr/
            ;;

        "mailu")
            # Deliberately not backing up certs as they can and should be
            # regenerated
            docker exec mail-backup rsync --recursive --archive --delete --quiet --times --relative --checksum --delete-missing-args /data/ /dav/ /dkim/ /filter/ /mail/ /overrides/ /redis/ /webmail/ $BACKUPDIR
            ;;

        "pihole")
            mkdir -p $BACKUPDIR/config
            mkdir -p $BACKUPDIR/dnsmasq
            docker exec pihole-backup rsync -rtav --delete-missing-args /config/adlists.list /config/adlists.list /config/auditlog.list /config/blacklist.txt /config/regex.list /config/setupVars.conf /config/whitelist.txt $BACKUPDIR/config
            docker exec pihole-backup rsync -rtav --delete-missing-args /dnsmasq/01-pihole.conf $BACKUPDIR/dnsmasq
            ;;

        "radarr")
            # These two files are the only ones that Radarr backs up itself
            docker cp radarr:/config/config.xml $BACKUPDIR/config.xml
            docker cp radarr:/config/radarr.db $BACKUPDIR/radarr.db
            ;;

        "sabnzbd")
            # There's only 1 file that needs backing up according to:
            # https://forums.sabnzbd.org/viewtopic.php?t=24102
            docker cp sabnzbd:/config/sabnzbd.ini $BACKUPDIR/sabnzbd.ini
            ;;

        "sonarr")
            # These two files are the only ones that Sonarr backs up itself
            docker cp sonarr:/config/config.xml $BACKUPDIR/config.xml
            docker cp sonarr:/config/sonarr.db $BACKUPDIR/sonarr.db
            ;;

        "syncthing")
            docker cp syncthing:/var/syncthing/config/cert.pem $BACKUPDIR/cert.pem
            docker cp syncthing:/var/syncthing/config/config.xml $BACKUPDIR/config.xml
            docker cp syncthing:/var/syncthing/config/key.pem $BACKUPDIR/key.pem
            ;;

        "transmission")
            docker exec transmission-backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args /config/ /backups/transmission/
            ;;

        "unifi-video")
            docker exec unifi-video-backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args --one-file-system /data/ /backups/unifi-video/
            ;;

        "www-toastboy")
            # This is a special case - for now, the cron sidecar copies its
            # backups directly into the backups volume
            ;;

        *)
            echo "Unrecognised backup name in do_backup"
            ;;
    esac
}

function do_post_backup {
    case "$BACKUPNAME" in

        *)
        ;;
    esac
}

function do_pre_restore {
    case "$BACKUPNAME" in

        "lidarr")
            # Delete all db files as per documentation
            docker exec lidarr rm -f /config/lidarr.db /config/lidarr.db-shm /config/lidarr.db-wal
            ;;

        "radarr")
            # Delete all db files as per documentation
            docker exec radarr rm -f /config/radarr.db /config/radarr.db-shm /config/radarr.db-wal
            ;;

        "sonarr")
            # Delete all db files as per documentation
            docker exec sonarr rm -f /config/sonarr.db /config/sonarr.db-shm /config/sonarr.db-wal
            ;;

        *)
            ;;
    esac
}

function do_restore {
    case "$BACKUPNAME" in

        "headphones")
            # Delete all db files as per documentation
            docker exec headphones rm -f /config/headphones.db /config/headphones.db-shm /config/headphones.db-wal
            # Stop the app to guarantee coherency
            docker stop headphones
            # Reinstate the files and start the app once more
            docker cp $BACKUPDIR/config.ini headphones:/config/config.ini
            docker cp $BACKUPDIR/headphones.db headphones:/config/headphones.db
            docker cp $BACKUPDIR/headphones.sql headphones:/config/headphones.sql
            ;;

        "jackett")
            docker exec jackett-backup rsync --recursive --archive --quiet --times --checksum /backups/jackett/ /config/
            ;;

        "jenkins")
            docker exec jenkins-backup rsync --recursive --archive --quiet --times --checksum /backups/jenkins/ /var/jenkins_home/
            ;;

        "lidarr")
            docker exec lidarr-backup rsync --recursive --archive --quiet --times --checksum /backups/lidarr/ /config/
            ;;

        "mailu")
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/data/ /data/
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/dav/ /dav/
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/dkim/ /dkim/
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/filter/ /filter/
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/mail/ /mail/
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/overrides/ /overrides/
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/redis/ /redis/
            docker exec mailu_backup rsync --recursive --archive --delete --quiet --times --checksum --delete-missing-args $BACKUPDIR/webmail/ /webmail/
            ;;

        "pihole")
            docker exec pihole-backup rsync -rtav --delete-missing-args /config/adlists.list $BACKUPDIR/config/* /config/
            docker exec pihole-backup rsync -rtav --delete-missing-args $BACKUPDIR/dnsmasq/* /dnsmasq/
            ;;

        "radarr")
            docker cp $BACKUPDIR/config.xml radarr:/config/config.xml
            docker cp $BACKUPDIR/radarr.db radarr:/config/radarr.db
            docker cp $BACKUPDIR/radarr.sql radarr:/config/radarr.sql
            ;;

        "sabnzbd")
            # Reinstate the files and start the app once more, making sure
            # we get file ownership and permissions right
            docker cp $BACKUPDIR/sabnzbd.ini sabnzbd:/config/sabnzbd.ini
            docker start sabnzbd
            docker exec sabnzbd chown abc:abc /config/sabnzbd.ini
            docker exec sabnzbd chmod 600 /config/sabnzbd.ini
            ;;

        "sonarr")
            docker cp $BACKUPDIR/config.xml sonarr:/config/config.xml
            docker cp $BACKUPDIR/sonarr.db sonarr:/config/sonarr.db
            docker cp $BACKUPDIR/sonarr.sql sonarr:/config/sonarr.sql
            ;;

        "syncthing")
            docker cp $BACKUPDIR/cert.pem syncthing:/var/syncthing/config/cert.pem
            docker cp $BACKUPDIR/config.xml syncthing:/var/syncthing/config/config.xml
            docker cp $BACKUPDIR/key.pem syncthing:/var/syncthing/config/key.pem
            ;;

        "transmission")
            docker exec transmission-backup rsync --recursive --archive --quiet --times --checksum /backups/transmission/ /config/
            ;;

        "unifi-video")
            docker exec unifi-video-backup rsync --recursive --archive --quiet --times --checksum /backups/unifi-video/ /data/
            ;;

        "www-toastboy")
            docker exec www-cron /root/mysqlrestore
            ;;

        *)
            echo "Unrecognised backup name in do_restore"
            ;;
    esac
}

function do_post_restore {
    case "$BACKUPNAME" in

        *)
        ;;
    esac
}

# Basic setup, we use the same file for both before and after,
# so we need to figure out which event has happened
if [ "$EVENTNAME" == "BEFORE" ]
then

    # If we're being run before a backup, extract the files we need
    if [ "$OPERATIONNAME" == "Backup" ]
    then
        do_pre_backup
        app_stop
        do_backup
        app_start
        do_post_backup
    fi

elif [ "$EVENTNAME" == "AFTER" ]
then

    # If we're being run after a restore, install the files into the container
    if [ "$OPERATIONNAME" == "Restore" ]
    then
        do_pre_restore
        app_stop
        do_restore
        app_start
        do_post_restore
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
