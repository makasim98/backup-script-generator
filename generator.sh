#!/bin/bash

echo "====================================================================================="
echo "Welcome to your interactive backup system"
echo "====================================================================================="

# --- Config Variables ---
SOURCE_PATHS=()
BACKUP_DESTINATION=""
CRON_ENTRY=""
BCKP_HISTORY_MAX_NUM=1
BCKP_HISTORY_MAX_AGE_DAYS=30
FORMAT=""

# Nicolas
add_bckp_src() {
    echo "Sources" 
}

get_max_history() {
    echo "History" 
}

get_bckp_format() {
    echo "Format" 
}

# Maxim
# TODO: Handle '~' expansion to the users home directory
add_bckp_target() {
    echo "--- Setting Backup Destination ---"
    read -e -p "Enter the destination path where your backups will be stored (e.g., /mnt/backups): " target    
    if [ ! -d "$target" ]; then
        echo "ERROR: '$target' is not a valid directory. No changes made."
        return
    elif [ ! -w "$target" ]; then
        echo "ERROR: User '$USER' (you) do not have write permissions to '$target'. No changes made."
        return
    fi

    BACKUP_DESTINATION="$target"
    echo "SUCCESS: Backup destination set to '$target'."
    echo "Note: Write permissions confirmed, no issues if backed-up by '$USER' user"
}

get_bckp_freq() {
    echo "Frequency" 
}

help() {
    echo "HELP" 
}
quit() {
    while true; do
        read -p "Are you sure you want to quit, discarding all changes? [y/n] " answer
        case "$answer" in
            [Yy]* ) exit 0 ;;
            [Nn]* ) return ;;
            * ) echo "Invalid input. Please enter 'y' or 'n'.";;
        esac
    done
}

list_curr_config() {
    echo "=============================="
    echo "Showing configuration:"
    echo -e "BACKUP_DESTINATION: $BACKUP_DESTINATION"
}
generate_script() {
    echo "Generationg Script"
}

# Interactive menu
# l) List current configurations (Summary of configured options)
# a) Add backup source (the directory/file we want to backup)
# t) Add backup target (Path to store the backup at)
# c) Frequency (cron for sheduing)
# h) History (How much/old do we keep before descarding the oldest one)
#       - Max number (discrad oldes after # buckups)
#       - Max age (discard backups older then AGE)
# f) Format (How to store it - tar, gzip, zip)
# g) Generate the Script from current config
# q) Quit (Cancel generation)

while true
do
    PS3="Chose one of the following options: "
    options=("Show Configuration" "Sources" "Target" "Frequency" "History" "Format" "Generate Script" "Help" "Quit")

    select opt in "${options[@]}"
    do
        case "$opt" in
            "Show Configuration") 
                list_curr_config
                break
                ;;
            "Sources") 
                add_bckp_src
                break
                ;;
            "Target") 
                add_bckp_target
                break
                ;;
            "Frequency") 
                get_bckp_freq
                break
                ;;
            "History") 
                get_max_history
                break
                ;;
            "Format") 
                get_bckp_format
                break
                ;;
            "Generate Script") 
                generate_script
                break
                ;;
            "Help") 
                help
                break
                ;;
            "Quit") 
                quit
                break
                ;;
            *)
                echo "Invalid option: Try Again!"
                ;;
        esac
    done
    echo ==============================================
done


































