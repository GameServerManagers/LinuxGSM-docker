#!/bin/bash

exit_handler () {
	# Execute the  shutdown commands
    echo "recieved SIGTERM stopping ${GAMESERVER}"
	./${GAMESERVER} stop
	exit 0
}

# Exit trap
echo "loading exit trap"
trap exit_handler SIGTERM

echo -e "Welcome to the LinuxGSM Docker"
echo -e "================================================================================"
echo -e "GAMESERVER: ${GAMESERVER}"
echo -e "UID: $UID"
echo -e ""
echo -e "LGSM_GITHUBUSER: ${LGSM_GITHUBUSER}"
echo -e "LGSM_GITHUBREPO: ${LGSM_GITHUBREPO}"
echo -e "LGSM_GITHUBBRANCH: ${LGSM_GITHUBBRANCH}"

echo -e ""
echo -e "Initalising"
echo -e "================================================================================"
# Correct permissions in home dir
echo "update permissions for linuxgsm"
sudo chown -R linuxgsm:linuxgsm /home/linuxgsm

# Copy linuxgsm.sh into homedir
if [ ! -e ~/linuxgsm.sh ]; then
    echo "copying linuxgsm.sh to /home/linuxgsm"
    cp /linuxgsm.sh ~/linuxgsm.sh
fi

# Setup game server
if [ ! -f "${GAMESERVER}" ]; then
    echo "creating ./${GAMESERVER}"
   ./linuxgsm.sh ${GAMESERVER}
fi

# Install game server
if [ -z "$(ls -A -- "serverfiles")" ]; then
    echo "installing ${GAMESERVER}"
    ./${GAMESERVER} auto-install
fi

echo "starting cron"
sudo cron

# Update game server
echo ""
echo "update ${GAMESERVER}"
./${GAMESERVER} update

echo ""
echo "start ${GAMESERVER}"
./${GAMESERVER} start
sleep 5
./${GAMESERVER} details

tail -f log/script/* &
wait $!

# with no command, just spawn a running container suitable for exec's
if [ $# = 0 ]; then
    tail -f /dev/null
else
    # execute the command passed through docker
    "$@"

    # if this command was a server start cmd
    # to get around LinuxGSM running everything in
    # tmux;
    # we attempt to attach to tmux to track the server
    # this keeps the container running
    # when invoked via docker run
    # but requires -it or at least -t
    tmux set -g status off && tmux attach 2> /dev/null
fi

exec "$@"
