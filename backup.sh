#!/bin/bash

BACKUPDIR="/mnt/storage/Backups/database/" # change location to where you want the databases to be dumped
LOCKFILE="/tmp/db_backup.lock"
RCLONELOCK="/tmp/rclone_backup.lock"
CLEAN="/tmp/clean.lock"

## Make the backup dirs, incase it doesn't exist
mkdir -p $BACKUPDIR

## Dump all the database tables to the harddrive
(
 flock -n 9 || { echo 'Unable to obtain lock'; exit 1 ; }
 echo "Backing up mySQL"
 cd $BACKUPDIR

 ulimit -n 64000
 time /mnt/storage/Backups/dumper.sh $BACKUPDIR   # change to location dumper sits in root

 ) 9>$LOCKFILE


###############################################################
## OPTIONAL UN COMMENT IF YOU WANT TO BACK UP TO Google Drive
## YOU WILL NEED RCLONE INSTALLED TO HAVE THIS WORKING
## Upload data to gdrive
###############################################################

#(
# flock -n 9 || { echo 'Unable to obtain lock'; exit 1 ; }
# echo "Uploading data to gDrive"
# ulimit -n 64000
# rclone --transfers 6 --checkers 4 --drive-chunk-size=131072 copy /mnt/storage/Backups Gdrive:/BackupsNew
#) 9>$RCLONELOCK

## Clean up the backup directories
(
 flock -n 9 || { echo 'Unable to obtain lock'; exit 1 ; }
 echo "Cleaning up backup directories"
 find /mnt/storage/Backups/database/* -type d -mtime +4 -exec rm -rf {} \;
) 9>$CLEAN
