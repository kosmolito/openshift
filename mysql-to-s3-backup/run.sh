#!/bin/bash
echo "login to aws"
aws configure set aws_access_key_id $ACCESS_KEY_ID && aws configure set aws_secret_access_key $SECRET_ACCESS_KEY
BACKUP_DATE=$(date +%Y-%m-%d-%H-%M-%S)
BACKUP_FOLDER=/tmp/db-backups
FILE_NAME=$MARIADB_DATABASE-$BACKUP_DATE.sql
FILE_PATH=$BACKUP_FOLDER/$MARIADB_DATABASE-$BACKUP_DATE.sql
echo "Starting backup for database $MARIADB_DATABASE into $FILE_PATH"
mysqldump -h $MARIADB_HOST -u $MARIADB_USER -p$MARIADB_PASSWORD $MARIADB_DATABASE > $FILE_PATH

if [ $? -eq 0 ]; then
    echo "Backup Successful"
    echo "Backing up to S3 bucket $BUCKET_NAME"
    aws s3 cp $FILE_PATH s3://$BUCKET_NAME
    if [ $? -eq 0 ]; then
        echo "Backup Successful"
        mkdir -p $BACKUP_FOLDER/success_sync_to_s3
        mv $FILE_PATH $BACKUP_FOLDER/success_sync_to_s3/$FILE_NAME
    else
        echo "Backup to S3 Failed!"
    fi
else
    echo "Backup Failed"
    mkdir -p $BACKUP_FOLDER/failed_sync_to_s3
    mv $FILE_PATH $BACKUP_FOLDER/failed_sync_to_s3/$FILE_NAME
fi