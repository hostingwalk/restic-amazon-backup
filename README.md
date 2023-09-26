## Directadmin Restic Backup using S3 Block Storage

# Requirements
* `restic >=v0.9.6`
* `zstd:  for mysql backups`

## Required: Install Restic

[restic](https://restic.net/) is a command-line tool for making backups.

Ubuntu:
```bash
$ apt-get install restic && apt-get install git

sudo apt-get update && sudo apt-get install -y software-properties-common && sudo add-apt-repository -y ppa:copart/restic && sudo apt-get update && sudo apt-get install -y restic git
````

CentOS:
```bash
$ yum install yum-plugin-copr && yum copr enable copart/restic && yum install restic && yum install git

sudo apt-get update && sudo apt-get install -y software-properties-common && sudo add-apt-repository -y ppa:copart/restic && sudo apt-get update && sudo apt-get install -y restic git
````

## Installguide Directadmin VPS Backup

Tip: The steps in this section will instruct you to copy files from this repo to system directories.

```bash
$ git clone https://github.com/payrequestio/directadmin-vps-backup.git
$ cd directadmin-vps-backup
$ sudo make install
````


### 1. Configure S3 credentials
Put these files in `/etc/restic/`:
* `env.sh`: Fill this file out with your S3 bucket settings. The reason for putting these in a separate file is that it can be used also for you to simply source, when you want to issue some restic commands. For example:
```bash
$ source /etc/restic/env.sh
$ restic snapshots    # You don't have to supply all parameters like --repo, as they are now in your environment!
````

### 2. Initialize remote repo
Now we must initialize the repository on the remote end:
```bash
source /etc/restic/env.sh && restic init
```

### 3. Script for doing the backup
Put this file in `/usr/local/sbin`:
* `directadmin-vps-backup.sh`: A script that defines how to run the backup. Edit this file to respect your needs in terms of backup which paths to backup, retention (number of backups to save), etc.

Put this file in `/`:
* `.backup_exclude`: A list of file pattern paths to exclude from you backups, files that just occupy storage space, backup-time, network and money.


### 4. Make first backup & verify
Now see if the backup itself works, by running

```bash
$ /usr/local/sbin/directadmin-vps-backup.sh
$ restic snapshots
````

### 5. Backup automatically; systemd service + timer
Now we can do the modern version of a cron-job, a systemd service + timer, to run the backup every day!


Put these files in `/etc/systemd/system/`:
* `directadmin-vps-backup.service`: A service that calls the backup script.
* `directadmin-vps-backup.timer`: A timer that starts the backup every day.


Now simply enable the timer with:
```bash
$ systemctl start directadmin-vps-backup.timer
$ systemctl enable directadmin-vps-backup.timer
````

You can see when your next backup is scheduled to run with
```bash
$ systemctl list-timers | grep directadmin-vps-backup
```

and see the status of a currently running backup with

```bash
$ systemctl status directadmin-vps-backup
```

or start a backup manually

```bash
$ systemctl start directadmin-vps-backup
```

You can follow the backup stdout output live as backup is running with:

```bash
$ journalctl -f -u directadmin-vps-backup.service
````

(skip `-f` to see all backups that has run)

