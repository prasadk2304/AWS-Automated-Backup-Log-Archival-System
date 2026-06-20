# Setup Guide

## AWS Automated Backup & Log Archival System

This document provides step-by-step instructions to deploy and configure an automated backup and log archival solution using AWS EC2, S3, IAM, CloudWatch, SNS, and Bash scripting.

---

## Architecture Overview

The solution performs the following operations:

1. Collects application logs and backup files from an EC2 instance.
2. Compresses files into a timestamped archive.
3. Generates SHA-256 checksums for integrity verification.
4. Uploads archives and checksum files to Amazon S3.
5. Sends custom metrics to Amazon CloudWatch.
6. Triggers notifications through Amazon SNS.
7. Automates execution using cron jobs.

---

## Prerequisites

* AWS account
* IAM user with administrative permissions
* Basic Linux command-line knowledge
* GitHub account (optional, for source code management)

---

## Services Used

* Amazon EC2
* Amazon S3
* AWS IAM
* Amazon CloudWatch
* Amazon SNS
* AWS Systems Manager Session Manager

---

## Step 1: Create an S3 Bucket

Navigate to:

```text
AWS Console → S3 → Create bucket
```

Configure the bucket:

| Setting             | Value                       |
| ------------------- | --------------------------- |
| Bucket name         | sukhoi-backup-archive       |
| Region              | Same region as EC2 instance |
| Block public access | Enabled                     |
| Versioning          | Enabled                     |
| Default encryption  | SSE-S3                      |

Create the following prefixes:

```text
backups/
checksums/
logs/
```

---

## Step 2: Create an IAM Role

Navigate to:

```text
AWS Console → IAM → Roles → Create role
```

Configuration:

* Trusted entity: AWS Service
* Use case: EC2

Attach the following policies:

* AmazonSSMManagedInstanceCore
* AmazonS3FullAccess
* CloudWatchAgentServerPolicy

Role name:

```text
EC2BackupRole
```

---

## Step 3: Launch an EC2 Instance

Navigate to:

```text
AWS Console → EC2 → Launch instance
```

Configuration:

| Setting       | Value                   |
| ------------- | ----------------------- |
| Name          | backup-server           |
| AMI           | Ubuntu Server 24.04 LTS |
| Instance type | t2.micro                |
| IAM role      | EC2BackupRole           |

Security group configuration:

| Type | Port | Source |
| ---- | ---- | ------ |
| SSH  | 22   | My IP  |

Ensure auto-assign public IP is enabled.

---

## Step 4: Connect to the Instance

Use Session Manager:

```text
EC2 → Instances → Select instance → Connect → Session Manager
```

Alternatively, connect using SSH:

```bash
ssh -i your-key.pem ubuntu@<PUBLIC_IP>
```

---

## Step 5: Install Required Packages

Update the system:

```bash
sudo apt update && sudo apt upgrade -y
```

Install dependencies:

```bash
sudo apt install -y awscli zip unzip jq tree git
```

Verify installation:

```bash
aws --version
git --version
```

---

## Step 6: Create Sample Data

Create directories:

```bash
sudo mkdir -p /backup
sudo mkdir -p /var/log/myapp
mkdir -p ~/scripts
```

Create a sample backup file:

```bash
echo "Sample database content" | sudo tee /backup/db.sql
```

Generate sample logs:

```bash
for i in {1..100}
do
  echo "$(date) - Application log entry $i" | sudo tee -a /var/log/myapp/app.log
done
```

Verify:

```bash
tree /backup
tree /var/log/myapp
```

---

## Step 7: Create the Backup Script

Create the script:

```bash
nano ~/scripts/backup.sh
```

Add the following content:

```bash
#!/bin/bash

DATE=$(date +%F-%H-%M-%S)

BUCKET="sukhoi-backup-archive"

ARCHIVE="backup-$DATE.tar.gz"
CHECKSUM="$ARCHIVE.sha256"

LOGFILE="$HOME/scripts/backup.log"

tar -czf /tmp/$ARCHIVE /backup /var/log/myapp

sha256sum /tmp/$ARCHIVE > /tmp/$CHECKSUM

aws s3 cp /tmp/$ARCHIVE s3://$BUCKET/backups/

UPLOAD_STATUS=$?

aws s3 cp /tmp/$CHECKSUM s3://$BUCKET/checksums/

if [ $UPLOAD_STATUS -eq 0 ]; then
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
```

Make the script executable:

```bash
chmod +x ~/scripts/backup.sh
```

---

## Step 8: Execute the Script

Run the script manually:

```bash
~/scripts/backup.sh
```

Verify uploaded files:

```bash
aws s3 ls s3://sukhoi-backup-archive/backups/

aws s3 ls s3://sukhoi-backup-archive/checksums/
```

Check execution logs:

```bash
cat ~/scripts/backup.log
```

---

## Step 9: Configure Cron Scheduling

Open crontab:

```bash
crontab -e
```

Schedule the backup job to run daily at 2:00 AM:

```cron
0 2 * * * /home/ssm-user/scripts/backup.sh
```

Verify:

```bash
crontab -l
```

---

## Step 10: Configure CloudWatch Monitoring

Navigate to:

```text
CloudWatch → Metrics → All Metrics → Custom Namespaces
```

Verify that the following namespace exists:

```text
BackupSystem
```

Confirm the metric:

```text
BackupStatus
```

Metric values:

* 1 = Success
* 0 = Failure

---

## Step 11: Configure SNS Notifications

Create an SNS topic:

```text
backup-alerts
```

Add an email subscription and confirm it.

Create a CloudWatch alarm:

| Setting   | Value        |
| --------- | ------------ |
| Namespace | BackupSystem |
| Metric    | BackupStatus |
| Condition | Less than 1  |

Configure the alarm action to send notifications to the SNS topic.

---

## Step 12: Configure Lifecycle Policies

Navigate to:

```text
S3 → sukhoi-backup-archive → Management → Lifecycle rules
```

Create rules:

| Prefix     | Retention |
| ---------- | --------- |
| backups/   | 30 days   |
| checksums/ | 30 days   |

---

## Step 13: Test Recovery Procedure

Create a test directory:

```bash
mkdir ~/restore-test
cd ~/restore-test
```

Download a backup:

```bash
aws s3 cp s3://sukhoi-backup-archive/backups/<backup-file>.tar.gz .
```

Download the checksum:

```bash
aws s3 cp s3://sukhoi-backup-archive/checksums/<backup-file>.tar.gz.sha256 .
```

Verify integrity:

```bash
sha256sum -c <backup-file>.tar.gz.sha256
```

Expected output:

```text
<backup-file>.tar.gz: OK
```

Extract the archive:

```bash
tar -xzf <backup-file>.tar.gz
```

Verify restored files:

```bash
tree backup
tree var/log/myapp
```

---

## Troubleshooting

### Session Manager Status Offline

Cause:

* IAM role attached after instance launch.

Solution:

* Reboot the instance.

---

### NoSuchBucket Error

Cause:

* Incorrect bucket name configured in the script.

Solution:

* Update the `BUCKET` variable in `backup.sh`.

---

### Permission Denied Writing Log File

Cause:

* Session Manager uses `ssm-user`.

Solution:

Use:

```bash
LOGFILE="$HOME/scripts/backup.log"
```

instead of hardcoded user paths.

---

## Project Validation Checklist

* [ ] EC2 instance created
* [ ] IAM role attached
* [ ] S3 bucket configured
* [ ] Backup script created
* [ ] Backups uploaded successfully
* [ ] Checksum verification completed
* [ ] Cron job configured
* [ ] CloudWatch metrics visible
* [ ] SNS alerts configured
* [ ] Recovery test completed
* [ ] Documentation updated
