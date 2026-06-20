# AWS Automated Backup & Log Archival System

An automated backup and log archival solution built using AWS services and Linux shell scripting.

The project collects application logs and system backups from an EC2 instance, compresses them into timestamped archives, generates SHA-256 checksums for integrity verification, uploads them securely to Amazon S3, and monitors backup health using CloudWatch and SNS notifications.

---

## Features

* Automated backup scheduling using cron jobs
* Compression of application logs and backup files
* Secure archival to Amazon S3
* SHA-256 checksum generation for data integrity
* Disaster recovery and restore validation
* Custom CloudWatch metrics for monitoring
* SNS email notifications for backup failures
* IAM role-based authentication
* Session Manager access without SSH dependency
* S3 lifecycle policies for cost optimization

---

## Architecture

![Architecture Diagram](architecture/architecture-diagram.png)

```text id="98ab6r"
+---------------------+
|      EC2 Instance   |
|---------------------|
| /backup             |
| /var/log/myapp      |
| backup.sh           |
+----------+----------+
           |
           v
+---------------------+
|   Bash Script       |
|---------------------|
| Compress Files      |
| Generate Checksum   |
| Upload to S3        |
| Push Metrics        |
+----------+----------+
           |
           v
+---------------------+
|     Amazon S3       |
|---------------------|
| backups/            |
| checksums/          |
| logs/               |
+----------+----------+
           |
           v
+---------------------+
|   CloudWatch        |
|---------------------|
| BackupStatus Metric |
+----------+----------+
           |
           v
+---------------------+
|       SNS           |
|---------------------|
| Email Notifications |
+---------------------+
```

---

## Technology Stack

* AWS EC2
* Amazon S3
* AWS IAM
* Amazon CloudWatch
* Amazon SNS
* AWS Systems Manager Session Manager
* Bash Scripting
* Cron
* Linux (Ubuntu)

---

## Repository Structure

```text id="5u3iqs"
aws-automated-backup-system/

├── README.md
├── scripts/
│   └── backup.sh
├── docs/
│   ├── setup-guide.md
│   ├── recovery-procedure.md
│   └── screenshots/
├── architecture/
│   └── architecture-diagram.png
├── iam/
│   └── ec2-backup-policy.json
└── .gitignore
```

---

## Workflow

1. Application logs and backup files are generated on the EC2 instance.
2. The backup script compresses files into a timestamped archive.
3. A SHA-256 checksum file is created.
4. Both files are uploaded to Amazon S3.
5. Custom metrics are pushed to CloudWatch.
6. CloudWatch alarms trigger SNS email notifications on failures.
7. Scheduled cron jobs automate the process.
8. Recovery procedures validate backup integrity.

---

## Prerequisites

* AWS account
* IAM user with appropriate permissions
* Ubuntu EC2 instance
* S3 bucket
* AWS CLI installed
* Git installed

---

## Installation and Setup

Clone the repository:

```bash id="pm7m3u"
git clone https://github.com/<your-username>/aws-automated-backup-system.git

cd aws-automated-backup-system
```

Make the script executable:

```bash id="dbn17w"
chmod +x scripts/backup.sh
```

Update the bucket name inside the script:

```bash id="i8db1x"
BUCKET="your-s3-bucket-name"
```

Execute the script:

```bash id="wex44t"
./scripts/backup.sh
```

Detailed deployment instructions are available in:

```text id="8mwz4v"
docs/setup-guide.md
```

---

## Recovery Procedure

Download the backup:

```bash id="aqo1qh"
aws s3 cp s3://<bucket-name>/backups/<backup-file>.tar.gz .
```

Download the checksum:

```bash id="gbnvvj"
aws s3 cp s3://<bucket-name>/checksums/<backup-file>.tar.gz.sha256 .
```

Verify integrity:

```bash id="n3txrx"
sha256sum -c <backup-file>.tar.gz.sha256
```

Extract the archive:

```bash id="yj3h3v"
tar -xzf <backup-file>.tar.gz
```

Expected result:

```text id="9goj1r"
<backup-file>.tar.gz: OK
```

---

## Monitoring and Alerting

The solution uses CloudWatch custom metrics:

| Metric       | Description                       |
| ------------ | --------------------------------- |
| BackupStatus | Indicates backup execution status |

Metric values:

* `1` = Success
* `0` = Failure

CloudWatch alarms send notifications through Amazon SNS.

---

## Security Considerations

* IAM roles are used instead of static credentials.
* S3 bucket public access is blocked.
* Bucket encryption is enabled.
* Session Manager eliminates the need for inbound SSH access.
* Checksums verify backup integrity.

---

## Troubleshooting

### Session Manager Offline

Cause:

* IAM role attached after instance launch.

Solution:

* Reboot the instance.

### NoSuchBucket Error

Cause:

* Incorrect S3 bucket name.

Solution:

* Update the `BUCKET` variable in `backup.sh`.

### Permission Denied Writing Logs

Cause:

* Session Manager uses `ssm-user`.

Solution:

Use:

```bash id="vmr3wv"
LOGFILE="$HOME/scripts/backup.log"
```

instead of hardcoded user paths.

---

## Future Improvements

* Infrastructure as Code using Terraform
* Cross-region S3 replication
* AWS Backup integration
* Multi-instance backup support
* KMS encryption for archives
* Automated restore testing
* Docker containerization
* CI/CD integration using GitHub Actions

---



---

## License

This project is licensed under the MIT License.
