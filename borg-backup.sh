#!/bin/sh

main_user='tscherf'

# Setting this, so the repo does not need to be given on the commandline:
export BORG_REPO="/office/nextcloud/${HOSTNAME}-backup/$(date +%Y-%m)"

# Setting this, so you won't be asked for your repository passphrase:
export BORG_PASSPHRASE='<secret>'
# or this to ask an external program to supply the passphrase:
#export BORG_PASSCOMMAND='pass show backup'

# some helpers and error handling:
trap 'echo $( date ) Backup interrupted >&2; exit 2' INT TERM

# Backup the most important directories into an archive named after
# the machine this script is currently running on:

# dbus settings
export DBUS_SESSION_BUS_ADDRESS='unix:path=/run/user/1000/bus'

if [ ! -d "${BORG_REPO}" ]; then
	mkdir -p "${BORG_REPO}"
	borg init --encryption=repokey-blake2
fi


borg create --compression lz4 --exclude-caches --exclude-from /home/$main_user/bin/exclude.txt ::'{hostname}-auto-{now}' \
	/home		\
	/etc		\
	/data		\
	/root


backup_exit=$?

# Use the `prune` subcommand to maintain 7 daily, 4 weekly and 6 monthly
# archives of THIS machine. The '{hostname}-' prefix is very important to
# limit prune's operation to this machine's archives and not apply to
# other machines' archives also:

borg prune                          \
    --prefix '{hostname}-auto-'     \
    --keep-daily    7               \
    --keep-weekly   4               \
    --keep-monthly  6               \

prune_exit=$?

# use highest exit code as global exit code
global_exit=$(( backup_exit > prune_exit ? backup_exit : prune_exit ))

chown -R $main_user $BORG_REPO

[ ${global_exit} -eq 1 ] && su tscherf -c 'notify-send "Backup and/or Prune finished with a warning"'
[ ${global_exit} -gt 1 ] && su tscherf -c 'notify-send "Backup and/or Prune finished with an error"'
[ ${global_exit} -eq 0 ] && su tscherf -c 'notify-send "Backup finished"'


exit ${global_exit}
