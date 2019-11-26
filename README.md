# Automatic restic backups using AWS S3 Storage

## Restic

[restic](https://restic.net/) is a command-line tool for making backups.

Unfortunately restic does not come pre-configured with a way to run automated backups.
Here follows a step-by step tutorial on how to set it up.


## Installguide

Tip: The steps in this section will instruct you to copy files from this repo to system directories.

```bash
$ git clone https://github.com/hostingwalk/restic-amazon-backup.git
$ cd hostingwalk/restic-amazon-backup
$ sudo make install
````


### 1. Configure AWS S3 credentials
Put these files in `/etc/restic/`:
* `b2_env.sh`: Fill this file out with your B2 bucket settings etc. The reason for putting these in a separate file is that it can be used also for you to simply source, when you want to issue some restic commands. For example:
```bash
$ source /etc/restic/aws-env.sh
$ restic snapshots    # You don't have to supply all parameters like --repo, as they are now in your environment!
````
* `aws-password.txt`: Put your Restic password in this file.

### 2. Initialize remote repo
Now we must initialize the repository on the remote end:
```bash
source /etc/restic/aws-env.sh
restic init
```

### 3. Script for doing the backup
Put this file in `/usr/local/sbin`:
* `restic_backup.sh`: A script that defines how to run the backup. Edit this file to respect your needs in terms of backup which paths to backup, retention (number of backups to save), etc.

Put this file in `/`:
* `.backup_exclude`: A list of file pattern paths to exclude from you backups, files that just occupy storage space, backup-time, network and money.


### 4. Make first backup & verify
Now see if the backup itself works, by running

```bash
$ /usr/local/sbin/restic_backup.sh
$ restic snapshots
````

### 5. Backup automatically; systemd service + timer
Now we can do the modern version of a cron-job, a systemd service + timer, to run the backup every day!


Put these files in `/etc/systemd/system/`:
* `restic-backup.service`: A service that calls the backup script.
* `restic-backup.timer`: A timer that starts the backup every day.


Now simply enable the timer with:
```bash
$ systemctl start restic-backup.timer
$ systemctl enable restic-backup.timer
````

You can see when your next backup is scheduled to run with
```bash
$ systemctl list-timers | grep restic
```

and see the status of a currently running backup with

```bash
$ systemctl status restic-backup
```

or start a backup manually

```bash
$ systemctl start restic-backup
```

You can follow the backup stdout output live as backup is running with:

```bash
$ journalctl -f -u restic-backup.service
````

(skip `-f` to see all backups that has run)



### 6. Email notification on failure
We want to be aware when the automatic backup fails, so we can fix it. Since my laptop does not run a mail server, I went for a solution to set up my laptop to be able to send emails with [postfix via my Gmail](https://easyengine.io/tutorials/linux/ubuntu-postfix-gmail-smtp/). Follow the instructions over there.

Put this file in `/usr/local/sbin`:
* `systemd-email`: Sends email using sendmail(1). This script also features time-out for not spamming Gmail servers and getting my account blocked.

Put this files in `/etc/systemd/system/`:
* `status-email-user@.service`: A service that can notify you via email when a systemd service fails. Edit the target email address in this file.

As you maybe noticed already before, `restic-backup.service` is configured to start `status-email-user.service` on failure.


### 8. Optional: automated backup checks
Once in a while it can be good to do a health check of the remote repository, to make sure it's not getting corrupt. This can be done with `$ restic check`.

There are some `*-check*`-files in this git repo. Install these in the same way you installed the `*-backup*`-files.


## Cron?
If you want to run an all-classic cron job instead, do like this:

* `etc/cron.d/restic`: Depending on your system's cron, put this in `/etc/cron.d/` or similar, or copy the contents to $(sudo crontab -e). The format of this file is tested under FreeBSD, and might need adaptions depending on your cron.
* `usr/local/sbin/cron_mail`: A wrapper for running cron jobs, that sends output of the job as an email using the mail(1) command.
