#!/bin/sh

prefix=$(dirname $0)

if [ ! -d "${prefix}/etc" ]; then
	echo "error"
	exit 1
fi

export $(<"${prefix}/etc/borg.conf")

# set the full backup intervall
if [ $FullBackup == "daily" ]; then
	DatePrefix="$(date +%Y-%m-%d)"
elif [ $FullBackup == "weekly" ]; then
	DatePrefix="$(date +%Y-KW%W)"
else
	DatePrefix="$(date +%Y-%m)"
fi

export BORG_REPO="${BaseDir}/${HOSTNAME}-backup/$DatePrefix"

# password
if [ ! -z $Password ] ;then
	export BORG_PASSPHRASE=$Password
fi

# some helpers and error handling:
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

# create repo when not exist
if [ ! -d "${BORG_REPO}" ]; then
	mkdir -p "${BORG_REPO}"
	borg init --encryption=repokey-blake2
fi

# create backup
borg create --compression lz4 --exclude-caches --exclude-from "${prefix}/etc/backup.conf" ::'{hostname}-auto-{now}' $(<"${prefix}/etc/backup.conf")

backup_exit=$?

# prune backup :: todo
borg prune --prefix '{hostname}-auto-' --keep-daily 7 --keep-weekly 4 --keep-monthly 6

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

# notify main user about finished job
if [ ! -z $MainUser ]; then
	#todo
	DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus'
	chown -R $MainUser $BORG_REPO
	[ ${global_exit} -eq 1 ] && su $MainUser -c 'notify-send "Backup and/or Prune finished with a warning"'
	[ ${global_exit} -gt 1 ] && su $MainUser -c 'notify-send "Backup and/or Prune finished with an error"'
	[ ${global_exit} -eq 0 ] && su $MainUser -c 'notify-send "Backup finished"'
fi

exit ${global_exit}
