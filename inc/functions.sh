#!/usr/bin/env bash
#-------------------------------------------------------------------------------#
#               HPC-LCB: HPC Linux Cluster Builder with CentOS 7.x              #
#-------------------------------------------------------------------------------#
#
# Functions: functions.sh
#

# Global variables.
# This script.
THIS_EXEC=$(basename "$0")

# Exit codes.
EXIT_CODE_SUCCESS=0
EXIT_CODE_ERROR=2

# Functions.
# Check root user.
exec_by_root_user() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "
        You must be root to do this. Please su - and run again $THIS_EXEC script."
        exit $EXIT_CODE_ERROR
    fi
}

# Check if the computing node does exists.
nodes_exist() {
    NODES_EXIST=$1
    GET_INFO_NODE=$(ls -l /tftpboot/pxelinux.cfg/$NODES_EXIST > /dev/null 2>&1)
    GET_INFO_NODE_CHECK=$?

    if [[ $GET_INFO_NODE_CHECK -eq 0 ]]; then
echo -e "-------------------------------------------------------------------
Remove computing node: $NODES_EXIST"
    else
echo -e "-------------------------------------------------------------------
Computing node: $NODES_EXIST does not exists!
Have a look at /etc/hosts file ...
-------------------------------------------------------------------"
        exit $EXIT_CODE_ERROR
    fi
}

# Get nodes state: UP/DOWN.
nodes_state() {
    IFS=' ' read -r -a MACHINES <<< $(cat /etc/pdsh/machines)
    for machine in ${MACHINES[@]}; do
        ping -w 1 -c 1 $machine > /dev/null 2>&1
        if [[ $? -eq 0 ]]; then
            NODES_STATUS=$?
        else
            NODES_STATUS=$?
            echo "Node: $machine is DOWN!"
        fi
    done

    # Messages.
    if [[ $NODES_STATUS -eq 0 ]]; then
        echo "ALL nodes state: UP ..."
    else
        echo "ERROR: some of the node(s) are DOWN!"
        exit $EXIT_CODE_ERROR
    fi
}

# User exists test.
user_exists() {
    USER_NAME=$1
    if [[ $(getent passwd $USER_NAME) ]] > /dev/null 2>&1; then
        echo "Username: $USER_NAME already exists!"
        echo "Try another username!"
        exit $EXIT_CODE_ERROR
    else
        echo "Username: $USER_NAME does not exist!"
        echo "Creating $USER_NAME username ..."
    fi
}

# Group exists test.
group_exists() {
    GROUP_NAME=$1
    if [[ $(getent group $GROUP_NAME) ]]; then
        echo "Groupname: $GROUP_NAME already exists!"
        echo "Try another groupname!"
        exit $EXIT_CODE_ERROR
    else
        echo "Groupname: $GROUP_NAME does not exist!"
        echo "Creating $GROUP_NAME groupname ..."
    fi
}
