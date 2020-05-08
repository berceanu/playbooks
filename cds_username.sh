#!/usr/bin/env bash
#-------------------------------------------------------------------------------#
#               HPC-LCB: HPC Linux Cluster Builder with CentOS 7.x              #
#-------------------------------------------------------------------------------#
#
# Create/Delete/Sync linux user accounts: cds_username.sh 
#
# Doc: https://www.tecmint.com/add-users-in-linux/
#      https://www.thegeekstuff.com/2009/04/chage-linux-password-expiration-and-aging  
#
# 1. How to Add a New User in Linux.
## useradd tecmint
# 2. Create a User with Different Home Directory.
## useradd -d /data/projects anusha
# 3. Create a User with Specific User ID.
## useradd -u 999 navin
# 4. Create a User with Specific Group ID.
## useradd -u 1000 -g 500 tarunika
# 5. Add a User to Multiple Groups.
## useradd -G admins,webadmin,developers tecmint
# 6. Add a User without Home Directory.
## useradd -M shilpi
# 7. Create a User with Account Expiry Date.
## useradd -e 2014-03-27 aparna
# => Next, verify the age of account and password with 'chage' command for user 
#    'aparna' after setting account expiry date.
## chage -l aparna
# 8. Create a User with Password Expiry Date.
# => The '-f' argument is used to define the number of days after a password 
#    expires. A value of 0 inactive the user account as soon as the password has 
#    expired. By default, the password expiry value set to -1 means never expire.
#    Here in this example, we will set a account password expiry date i.e. 45 days
#    on a user 'tecmint' using '-e' and '-f' options.
## useradd -e 2014-04-27 -f 45 tecmint 
# 9. Add a User with Custom Comments.
## useradd -c "Manis Khurana" mansi
# 10. Change User Login Shell.
## useradd -s /sbin/nologin tecmint
# 11. Add a User with Specific Home Directory, Default Shell and Custom Comment.
## useradd -m -d /var/www/ravi -s /bin/bash -c "TecMint Owner" -U ravi
# 12. Add a User with Home Directory, Custom Shell, Custom Comment and UID/GID.
## useradd -m -d /var/www/tarunika -s /bin/zsh -c "TecMint Technical Writer" -u 1000 -g 1000 tarunika
# 13. Add a User with Home Directory, No Shell, Custom Comment and User ID.
## useradd -m -d /var/www/avishek -s /usr/sbin/nologin -c "TecMint Sr. Technical Writer" -u 1019 avishek
# 14. Add a User with Home Directory, Shell, Custom Skell/Comment and User ID.
## useradd -m -d /var/www/navin -k /etc/custom.skell -s /bin/tcsh -c "No Active Member of TecMint" -u 1027 navin
# 15. Add a User without Home Directory, No Shell, No Group and Custom Comment.
## useradd -M -N -r -s /bin/false -c "Disabled TecMint Member" clayton
# 16. List the password and its related details for an user.
## chage –-list username (or) chage -l username
# 17. Set Password Expiry Date for an user using chage option -M
## chage -M number-of-days username
# 18. Set the Account Expiry Date for an User.
## chage -E "2009-05-31" username
# 19. Force the user account to be locked after X number of inactivity days.
## chage -I 10 username
# 20. How to disable password aging for an user account?
## chage -m 0 -M 99999 -I -1 -E -1 username
# NOTE:
# => -m 0 will set the minimum number of days between password change to 0.
#    -M 99999 will set the maximum number of days between password change to 99999.
#    -I -1 (number minus one) will set the “Password inactive” to never.
#    -E -1 (number minus one) will set “Account expires” to never.
#

STORAGE=/data/storage
SCRATCH=/scratch

# Loading functions from: functions.sh
source inc/functions.sh

# Check root user.
exec_by_root_user

# Get nodes state: UP/DOWN.
nodes_state

# Create username function. 
create_user() {
    read -p "Create username: " USER_NAME

    # Run user_exits() test function.
    user_exists $USER_NAME

    # Enter user's full name.
    read -p "Enter $USER_NAME's full name: " FULL_NAME 
    useradd -c "$FULL_NAME" -m -d $STORAGE/$USER_NAME -s /bin/bash $USER_NAME
    passwd $USER_NAME

    # User will be asked to change password on the first login.
    chage -d 0 $USER_NAME
    
    # User ID & Group ID.
    USERID=$(id -u $USER_NAME)
    GROUPID=$(id -g $USER_NAME)
    echo -e "
User/Group ID for: $USER_NAME
 User ID is: $USERID
 Group ID is: $GROUPID
"

# User's account/password expiration date.
USER_STATUS=$(chage -l $USER_NAME)
echo -e "-------------------------------------------------------------------------------
ACCOUNT/PASSWORD expiration date for: $USER_NAME
-------------------------------------------------------------------------------"
echo -e "$USER_STATUS"
echo -e "-------------------------------------------------------------------------------
Do you want to change user's ACCOUNT/PASSWORD expiration date?"
read -p "Select [y/n]: " CHANGE_ACC_Y_N
    if [[ $CHANGE_ACC_Y_N == "y" ]]; then
        read -p "Select [acc/pass/both]: " CHANGE_ACC_PASS_BOTH 
        if [[ $CHANGE_ACC_PASS_BOTH == "acc" ]]; then
            read -p "Enter the account expiry date [yyyy-mm-dd]: " USER_EXPIRY_ACC
            usermod -e $USER_EXPIRY_ACC $USER_NAME
        elif [[ $CHANGE_ACC_PASS_BOTH == "pass" ]]; then
            read -p "Enter the password expiry [days]: " USER_EXPIRY_PASS
            chage -M $USER_EXPIRY_PASS $USER_NAME
        elif [[ $CHANGE_ACC_PASS_BOTH == "both" ]]; then
            read -p "Enter the account expiry date [yyyy-mm-dd]: " USER_EXPIRY_ACC
            read -p "Enter the password expiry [days]: " USER_EXPIRY_PASS
            usermod -e $USER_EXPIRY_ACC $USER_NAME
            chage -M $USER_EXPIRY_PASS $USER_NAME
        else
            echo "Continuing with the setup ..."
        fi
    else
        echo "Continuing with the setup ..." 
    fi

    # We have to keep UserIDs/GroupIDs the same across the HPC, which is done below.
    sleep 2
    pdsh groupadd $USER_NAME -g $GROUPID
    pdsh useradd -M $USER_NAME -u $USERID -g $USER_NAME -d $STORAGE/$USER_NAME -s /bin/bash 

    # Create user's scratch folder.
    pdsh "cd $SCRATCH; mkdir $USER_NAME; chown $USER_NAME:$USER_NAME $USER_NAME; chmod 700 $USER_NAME"
    
    # Generate ssh-key.
    su $USER_NAME -c "ssh-keygen"
    cat $STORAGE/${USER_NAME}/.ssh/id_rsa.pub >> $STORAGE/${USER_NAME}/.ssh/authorized_keys
    chown ${USER_NAME}:${USER_NAME} $STORAGE/${USER_NAME}/.ssh/authorized_keys

    # Note: to enable user quota support by /home filesystem, add "quota" to the options of /home in /etc/fstab.
    # After that unmount /home ("service nfs-server stop" if busy), then mount again (+ "service nfs-server start")
    # to check user USERNAME quota do: "quota -us USERNAME"
    echo ""
    read -p "Enter quota for $USER_NAME [y/n]: " Y_N

    if [[ $Y_N == "y" ]]; then
        read -p "$USER_NAME's quota in GB: " QUOTA
        read -p "Quota up to in GB: " QUOTA_UP_TO
        # read -p "Period of grace in weeks: " GRACE_PERIOD
        QUOTA_FINAL=$(($QUOTA*1048576))
        QUOTA_UP_TO_FINAL=$(($QUOTA_UP_TO*1048576))
        # GRACE_PERIOD_FINAL=$(($GRACE_PERIOD*10000000))
        
        # 256 Gb quota for users' homes (with up to 1Tb 7 day grace period)
        # setquota -u $USER_NAME 268435456 1073741824 10000000 10000000 /home
        setquota -u $USER_NAME $QUOTA_FINAL $QUOTA_UP_TO_FINAL 1000000 1000000 $STORAGE

echo -e "
Quota for $USER_NAME is: 
-------------------------------------------------------------------------------
Quota in KB: $QUOTA_FINAL with space up to: $QUOTA_UP_TO_FINAL
Quota in GB: $QUOTA       with space up to: $QUOTA_UP_TO
Grace period: 7 days, use 'edquota -t' to change it.
-------------------------------------------------------------------------------
Show disk space usage - by USERS.
$(xfs_quota -x -c "report -h -u" /home)
-------------------------------------------------------------------------------"

    elif [[ $Y_N == "n" ]]; then
        echo "Quota for $USER_NAME is: $(quota -us $USER_NAME)"
    else
        echo "Quota for $USER_NAME HAS NOT BEEN configured. Bye!"
    fi
}

# Final user's information.
# Final status: account/passord expiration date.
final_user_info() {
USER_STATUS=$(chage -l $USER_NAME)
echo -e "Final information.
------------------
You've added user: $USER_NAME
Full name: $(finger $USER_NAME |head -n1 |cut -d : -f3)
ACCOUNT/PASSWORD expiration date for: $USER_NAME
-------------------------------------------------------------------------------"
echo -e "$USER_STATUS"
echo "-------------------------------------------------------------------------------"
}

# Sync username function. 
sync_user() {
    read -p "Sync username: " USER_NAME

    # User exits test.
    if ! getent passwd $USER_NAME > /dev/null 2>&1; then
        echo "Username: $USER_NAME does not exist!"
        echo "Try another username!"
        exit $EXIT_CODE_ERROR
    else
        echo "Continuing ... syncing $USER_NAME"
    fi

    # Enter node(s) name.
    read -p "Sync node(s) [node/all]: " SYNC_NODE

    if [[ $SYNC_NODE == "all" ]]; then
        # UserID & GroupID.
        USERID=$(id -u $USER_NAME)
        GROUPID=$(id -g $USER_NAME)
echo -e "
User/Group ID for: $USER_NAME
 User ID is: $USERID
 Group ID is: $GROUPID
"

        # We have to keep UIDs the same across the HPC, which is done below.
        sleep 2
        pdsh groupadd $USER_NAME -g $GROUPID
        pdsh useradd -M $USER_NAME -u $USERID -g $USER_NAME -d $STORAGE/$USER_NAME -s /bin/bash

        # Create user's scratch folder.
        pdsh "cd $SCRATCH; mkdir $USER_NAME; chown $USER_NAME:$USER_NAME $USER_NAME; chmod 700 $USER_NAME"

    elif [[ $SYNC_NODE == "node" ]]; then
        read -p "Enter node name [node-xx]: " NODE_NAME

        # Check if the computing node does exist.
        GET_INFO_NODE=$(ls -l /tftpboot/pxelinux.cfg/$NODE_NAME > /dev/null 2>&1)
        GET_INFO_NODE_CHECK=$?
        if [[ $GET_INFO_NODE_CHECK -eq 0 ]]; then
            echo "Sync computing node: $NODE_NAME"

        # UserID & GroupID.
        USERID=$(id -u $USER_NAME)
        GROUPID=$(id -g $USER_NAME)
    echo -e "
User/Group ID for: $USER_NAME
 User ID is: $USERID
 Group ID is: $GROUPID
"

        # We have to keep UIDs the same across the HPC, which is done below.
        sleep 2
        pdsh -w $NODE_NAME groupadd $USER_NAME -g $GROUPID
        pdsh -w $NODE_NAME useradd -M $USER_NAME -u $USERID -g $USER_NAME -d $STORAGE/$USER_NAME -s /bin/bash

        # Create user's scratch folder.
        pdsh -w $NODE_NAME "cd $SCRATCH; mkdir $USER_NAME; chown $USER_NAME:$USER_NAME $USER_NAME; chmod 700 $USER_NAME"

        else
            echo -e "------------------------------------------------
 Computing node: $NODE_NAME does not exists!
------------------------------------------------"
            exit $EXIT_CODE_ERROR
        fi
    else
        echo "Wrong selection, bye!"
        exit $EXIT_CODE_ERROR
    fi
}

# Delete username function.
delete_user() {
    read -p "Delete username: " USER_NAME

    # User exits test.
    if getent passwd $USER_NAME > /dev/null 2>&1; then
        echo "Username: $USER_NAME exist!"
        echo "Continuing ... removing $USER_NAME"
    else
        echo "Username: $USER_NAME does not exists!"
        echo "Try another username!"
        exit $EXIT_CODE_ERROR
    fi

    # Remove user's scratch folder.
    pdsh cd $SCRATCH
    echo -e "
    Removing: $SCRATCH/$USER_NAME folder ...
    "
    pdsh rm -rf $SCRATCH/$USER_NAME 

    # Delete username/group: computing nodes.
#    pdsh groupdel $USER_NAME
    pdsh userdel $USER_NAME

    # Delete username/group: head-node.
#    groupdel $USER_NAME
    userdel $USER_NAME

    # Remove home folder: head-node.
    read -p "    Remove $USER_NAME's home folder [y/n]: " REMOVE_HOME_FOLDER
    if [[ "$REMOVE_HOME_FOLDER" == "y" ]]; then
        # Remove user's home folder.
        echo -e "
    Removing: $STORAGE/$USER_NAME ..."
        rm -fr $STORAGE/$USER_NAME
        if [[ $? -eq 0 ]]; then
        echo -e "
    $STORAGE/$USER_NAME has been removed!
    "
        else
        echo -e "
    Cannot remove: $STORAGE/$USER_NAME
    "
        fi
    elif [[ "$REMOVE_HOME_FOLDER" == "n" ]]; then
        # Do not remove user's home folder.
        echo -e "
    $USER_NAME's home folder: 
    $STORAGE/$USER_NAME has not been removed!
    "
        exit
    else
        echo -e "
    Wrong selection: 
    $STORAGE/$USER_NAME has not been removed!
    "
        exit $EXIT_CODE_ERROR
    fi
}

# Create/Delete username.
echo "--------------------------------------"
read -p "Create/Delete/Sync username [c/d/s]: " CREATE_X_DELETE
echo "--------------------------------------"
if [[ "$CREATE_X_DELETE" == "c" ]]; then
    # Run create_user() function.
    create_user
    # Run final_user_infor() function.
    final_user_info
elif [[ "$CREATE_X_DELETE" == "d" ]]; then
    # Run delete_user() function.
    delete_user
elif [[ "$CREATE_X_DELETE" == "s" ]]; then
    # Run sync_user() function.
    sync_user
else
    echo "Wrong selection, bye!"
    exit $EXIT_CODE_ERROR
fi





