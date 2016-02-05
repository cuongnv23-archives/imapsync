#! /bin/bash

# This script will migrate mailbox but does not require to know user's password.
# We will use an user name 'migrator' which has full permission to access other users' mailboxes.
# To give 'migrator' a full permission, on exchange server, execute below command:
# Add-MailboxPermission -Identity user_email -User migrator -AccessRights FullAccess
# Exchange server must have IMAP enabled (https://technet.microsoft.com/en-us/library/bb124489%28v=exchg.150%29.aspx)


LOG_FAILED="/var/log/imapsync/fails.log"
LOG_DIR="/var/log/imapsync"

DEFAULT_BUFFERSIZE="49152000"
DEFAULT_USERLIST="users.txt"



function usage() {

	echo "Usage: $0 -h [help] -d [domain_name] -S [exchange_server] -D [cyrus_server] -u [auth_user] -p [auth_pass] -i [input_file]"
	echo ""
	echo "-S: MANDATORY. IP or hostname of exchange server."
	echo "-D: MANDATORY. IP or hostname of cyrus server."
	echo "-u: MANDATORY. User which has full access to other users' mailbox."
	echo "-p: MANDATORY. Password of migration user."
	echo "-d: MANDATORY. Domain name of email users."
	echo "-i: file contains list of users. Default is ./users.txt"
	echo "-b: buffer size. Default is 49152000 bytes"


}

# Check input parameters and set default values

defaults() {

	if [ -z ${SRC_SRV} ]; then
		echo "Invalid input! No source server specified!"
		exit
	elif [ -z ${DST_SRV} ]; then
		echo "Invalid input! No destination server specified!"
		exit
	elif [ -z ${MIG_USER} ]; then
		echo "Invalid input! No migration user specified!"
		exit
	elif [ -z ${MIG_PWD} ]; then
		echo "Invalid input! No password of migration user specified!"
		exit
	elif [ -z ${DOMAIN} ]; then
		echo "Invalid input! No domain specified"
		exit
	fi

	if [ -z ${USER_LIST} ]; then
		USER_LIST=${DEFAULT_USERLIST}
	fi
	if [ -z ${BUFFERSIZE} ]; then
		BUFFERSIZE=${DEFAULT_BUFFERSIZE}
	fi

}


while getopts ":h:S:D:u:p:i:b:d:" opt; do
	case $opt in
		h)
			usage && exit 1
			;;
		S)
			SRC_SRV=${OPTARG}
			;;
		D)
			DST_SRV=${OPTARG}
			;;
		u)
			MIG_USER=${OPTARG}
			;;
		p)
			MIG_PWD=${OPTARG}
			;;
		i)
			USER_LIST=${OPTARG}
			if [ ! -f ${USER_LIST} ]; then
				echo "${USER_LIST}: No such file or directory"
				exit
			fi
			;;
		b)
			BUFFERSIZE=${OPTARG}
			;;
		d)
			DOMAIN=${OPTARG}
			;;
		*)
			usage && exit 1
			;;
	esac
done

if [ ! -d ${LOG_DIR} ]; then
	mkdir ${LOG_DIR}
fi

defaults

while read email passwd
do

	LOG_FILE=${LOG_DIR}/imapsync_${email}.log
	echo "Migrating mailboxes for ${email}..."

	/usr/bin/imapsync \
	--nofoldersizes --nofoldersizesatend --buffersize ${BUFFERSIZE} \
	--host1 ${SRC_SRV} \
	--exclude "Calendar|Contacts|Journal|Notes|Tasks|RSS\ Feeds|Sync\ Issues" \
	--regextrans2 "s/^Sent\ Items/Sent/" \
	--regextrans2 "s/^Deleted\ Items/Trash/" \
	--regextrans2 "s/^Junk\ Email/Junk/" \
	--authuser1 "${MIG_USER}@${DOMAIN}" \
	--user1 ${email} \
	--password1 "${MIG_PWD}" \
	--authmech1 "PLAIN" \
	--host2 ${DST_SRV} --user2  ${email} \
	--ssl1 --subscribeall \
	--authmech2 "PLAIN" \
	--password2 "${passwd}" > ${LOG_FILE}

	if [ $? -ne 0 ]; then
		echo "Processing mailbox for ${email} failed!";  >> ${LOG_FAILED}
	fi
	echo "Done!"

done < ${USER_LIST}

if [ -f ${LOG_FAILED} ]; then
	fails=`cat ${LOG_FAILED} | wc -l`
	echo "Mailboxes of ${fails} emails not migrated!"
fi
