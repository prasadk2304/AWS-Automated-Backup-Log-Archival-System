#!/bin/bash

DATE=$(date +%F-%H-%M-%S)

BUCKET="sukhoi-backup-archive"

ARCHIVE="backup-$DATE.tar.gz"

CHECKSUM="$ARCHIVE.sha256"

LOGFILE="/home/scripts/backup.log"

tar -czf /tmp/$ARCHIVE /backup /var/log/myapp

sha256sum /tmp/$ARCHIVE > /tmp/$CHECKSUM

aws s3 cp /tmp/$ARCHIVE s3://$BUCKET/backups/

UPLOAD_STATUS=$?

aws s3 cp /tmp/$CHECKSUM s3://$BUCKET/checksums/

if [ $UPLOAD_STATUS -eq 0 ]
then
    echo "$(date) Backup successful" >> $LOGFILE

    aws cloudwatch put-metric-data \
      --namespace BackupSystem \
      --metric-name BackupStatus \
      --value 1
else
    echo "$(date) Backup failed" >> $LOGFILE

    aws cloudwatch put-metric-data \
      --namespace BackupSystem \
      --metric-name BackupStatus \
      --value 0
fi

rm -f /tmp/$ARCHIVE
rm -f /tmp/$CHECKSUM
