#!/bin/bash
source ./util.sh
source ./script_templates.sh

BACKUP_SCRIPT_CONTENT=""

# --- Config Variables ---
SOURCE_PATHS=()
BACKUP_DESTINATION=""
CRON_ENTRY=""
BCKP_HISTORY_MAX_NUM=1
FORMAT=""

# --- Source Configuration ---
bckp_src_header() {
    clear
    echo "===================================="
    echo "--- Backup Source Configuration  ---"
    echo "===================================="
}

bckp_srs_menu() {  
    while true
    do
        bckp_src_header
        local PS3="Choose one of the actions: "
        local options=("Add source" "Remove source" "List configured sources" "Back")

        select opt in "${options[@]}"
        do
            case "$opt" in
                "Add source")
                    bckp_src_add
                    break
                    ;;
                "Remove source")
                    bckp_src_remove
                    break
                    ;;
                "List configured sources")
                    bckp_src_header
                    bckp_src_list
                    echo -en "\nPress ENTER key to return to the menu..."; read
                    break
                    ;;
                "Back") 
                    return;;
                *) 
                    echo "Invalid option: Try again!" ;;
            esac
        done
    done
}

bckp_src_add() {
    bckp_src_header
    while true
    do
        echo "Enter the full source path of the directory to backup (e.g., /home/user/folder) OR enter 'done' when DONE: "
        read -e -p "> " src

        if [[ "$src" == "done" ]]; then
            return
        fi

        if [ -n "$src" ] && [ -d "$src" ]; then
            SOURCE_PATHS+=("$src")
            echo "SUCCESS: Source directory '$src' added to the backup list."
        else
            echo "ERROR: '$src' is not a valid directory."
        fi
    done
}

bckp_src_remove() {
    while true
    do
        bckp_src_header
        if [ ${#SOURCE_PATHS[@]} -eq 0 ]; then
            echo "ERROR: The source list is currently empty. Nothing to remove."
            echo -en "\nPress ENTER key to return to the menu..."; read
            return
        else
            echo "--- Currently configured Sources ---"
            local PS3="Choose the source you want to remove: "
            select path_to_remove in "${SOURCE_PATHS[@]}" "Cancel"
            do
                if [[ "$path_to_remove" == "Cancel" ]] ; then
                    return
                elif [ -n "$path_to_remove" ]; then
                    local index=$((REPLY - 1))
                    unset 'SOURCE_PATHS[$index]'
                    SOURCE_PATHS=("${SOURCE_PATHS[@]}")
                    break
                fi
            done
        fi
    done
}

bckp_src_list () {
    bckp_src_header
    if [ ${#SOURCE_PATHS[@]} -eq 0 ]
    then
	    echo "SOURCE PATHS: No source directories have been added yet."
    else
	    echo "SOURCE PATHS: "
	    for src in "${SOURCE_PATHS[@]}"
	    do
		    echo "    - $src"
	    done
    fi
}

# --- Destination Configuration ---
bckp_dest_header() {
    clear
    echo "========================================="
    echo "--- Backup Destination Configuration  ---"
    echo "========================================="
}

bckp_dest_set() {
    bckp_dest_header
    while true
    do
        echo "Enter the full destination path where your backups will be stored (e.g., /mnt/backups) Or 'done' to CANCEL : "
        read -e -p "> " dest

        # Check if the destination path is empty
        if [ -z "$dest" ]; then
            echo "ERROR: Destination path cannot be empty. Try again."
            continue
        fi

        if [[ "$dest" == "done" ]]; then
            return
        fi

        # Check if provided path exists
        if [ -d "$dest" ]; then
            # Check for write user permissions
            if [ ! -w "$dest" ]; then
                echo "ERROR: User '$USER' does not have write permissions to existing directory '$dest'. Try again."
                continue
            fi
            
        # If dir does not extist, recusively check closest existing parent folder to confirm user permissions
        else
            path_to_check="$dest"

            # Loop up the directory tree to find the nearest existing directory
            while [ ! -d "$path_to_check" ] && [ "$path_to_check" != "/" ]; do
                path_to_check=$(dirname "$path_to_check")
            done

            # Check if we have write permissions in the directory
            if [ ! -w "$path_to_check" ]; then
                echo "ERROR: User '$USER' (you) does not have write permissions in '$path_to_check' to create '$dest'. Try again."
                continue
            fi
        fi
        break
    done

    BACKUP_DESTINATION="$dest"
    echo "SUCCESS: Backup destination set to '$dest'."
    echo "Note: Write permissions confirmed, no issues if backed-up by '$USER' user"
    echo -en "\nPress ENTER key to return to the menu..."; read
}

# --- Backup History Configuration ---
bckp_history_header() {
    clear
    echo "====================================="
    echo "--- Backup History Configuration  ---"
    echo "====================================="
}

bckp_history_menu() {
    while true
    do
        bckp_history_header
        local PS3="Choose one of the actions: "
        local options=("Max Number of Backups" "Back")

        select opt in "${options[@]}"
        do
            case "$opt" in
                "Max Number of Backups")
                    bckp_history_max_num
                    break
                    ;;
                "Back") 
                    return;;
                *) 
                    echo "Invalid option: Try again!" ;;
            esac
        done
    done
}

bckp_history_max_num() {
    while true
    do
        echo "Maximum amount of backups preserved at a time (default: 1): "
        read -e -p "> " bckp_num

        if [[ "$bckp_num" =~ ^[0-9]+$ ]] && [ "$bckp_num" -gt 0 ]; then 
            BCKP_HISTORY_MAX_NUM=$bckp_num
            echo -e "SUCCESS: Maximum number of backup instances is set to $bckp_num."
            break
        else
            echo -e "ERROR: Provided quantity '$bckp_num' is not a positive integer. Try again"
        fi
    done

    echo -en "\nPress ENTER key to return to the menu..."; read
}

# --- Backup Format Configuration ---
bckp_format_header() {
    clear
    echo "====================================="
    echo "--- Backup Shedule Configuration  ---"
    echo "====================================="
}

bckp_format_set() {
    bckp_format_header
    local PS3="Choose a backup format: "
    local options=("tar" "tar.gz (gzip)" "zip" "Back")
    local cmd=""

    select opt in "${options[@]}"
    do
	    case "$opt" in
		    "tar")
			    FORMAT="tar"
                cmd="tar"
			    # echo "SUCCESS: Backup format set to 'tar'."
			    break;;
		    "tar.gz (gzip)")
			    FORMAT="tar.gz"
                cmd="gzip"
			    # echo "SUCCESS Backup format set to 'tar.gz'."
			    break;;
	 	    "zip")
			    FORMAT="zip"
                cmd="zip"
			    # echo "SUCCESS: Backup format set to 'zip'."
			    break;;
		    "Back")
			    return;;
		    *)
			    echo "Invalid option: Please try again.";;
	    esac
    done

    echo "SUCCESS Backup format set to '$opt'."
    if ! check_command_installed $cmd; then
        echo "WARNING: '$cmd' command is not installed. The generated script may fail."
    fi
    echo -en "\nPress ENTER key to return to the menu..."; read
}

# --- Backup Shedule Configuration (CRON) ---
bckp_cron_header() {
    clear
    echo "====================================="
    echo "--- Backup Shedule Configuration  ---"
    echo "====================================="
}
bckp_cron_set() {
    bckp_cron_header
    while true
    do
        read -p "Enter the shedule the backups will follow in CRON format (e.g. '* * * * *') or 'done' to CANCEL: " cron_str

        if [ -z "$cron_str" ]; then
            echo "ERROR: The provided cron shedule cannot be empty. Try again."
            continue
        fi

        if [[ "$cron_str" == "done" ]]; then
            return
        fi

        if is_valid_cron "$cron_str"; then
            CRON_ENTRY="$cron_str"
            echo "SUCCESS: Shedule set to '$cron_str'."
            echo -en "\nPress ENTER key to return to the menu..."; read
            return
        fi
    done
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
    echo "--- Showing configuration: ---"
    bckp_src_list

    echo -e "BACKUP_DESTINATION: $BACKUP_DESTINATION"
    echo -e "BACKUP FORMAT: $FORMAT"

    echo -e "CRON SHEDULE: $CRON_ENTRY"
    echo -e "MAX NUMBER OF BACKUPS: $BCKP_HISTORY_MAX_NUM"
}

generate_script() {
    # Check that all required Configs are set
    if [ ${#SOURCE_PATHS[@]} -eq 0 ]; then
        echo "ERROR: No source directories have been added."
	echo "Please add at least one source directory before generating the script."
        read -n 1 -s -r -p $'\nPress any key to return to the menu...'
        return
    elif [ -z "$BACKUP_DESTINATION" ]; then
       echo "ERROR: No destination path provided."
       echo "Please set a backup destination path first."
       read -n 1 -s -r -p $'\nPress any key to return to the menu...'
       return 
    elif [ -z "$FORMAT" ]; then
        echo "ERROR: No archiving format provided."
	echo "Please choose a format like 'tar' or 'zip'."
        read -n 1 -s -r -p $'\nPress any key to return to the menu...'
        return 
    fi


    echo -e "\n========== Generating Script ==========\n"
    list_curr_config

    ##### GENERATE THE SCRIPT HERE #####

    BACKUP_SCRIPT_CONTENT=$(generate_script_header)
    BACKUP_SCRIPT_CONTENT+=$(generate_script_configs "${SOURCE_PATHS[@]}" "$BACKUP_DESTINATION" "$BCKP_HISTORY_MAX_NUM" "$FORMAT")
    BACKUP_SCRIPT_CONTENT+=$(generate_script_body)

    ##### GENERATION FINISHED #####

    echo -e "\nEnter the full path where you want to save the backup script (e.g., /home/user/backup.sh): "
    read -r SCRIPT_PATH
    if [ -z "$SCRIPT_PATH" ]
    then
	    echo "No path provided. Aborting script generation."
	    return
    fi
    
    if [ -d "$SCRIPT_PATH" ]
    then
	    SCRIPT_PATH="${SCRIPT_PATH%/}/backup.sh"
    fi


    DIR_PATH=$(dirname "$SCRIPT_PATH")
    if [ ! -d "$DIR_PATH" ] || [ ! -w "$DIR_PATH" ]; then
        echo "Directory '$DIR_PATH' does not exist or is not writable."
        return
    fi

    echo "$BACKUP_SCRIPT_CONTENT" > "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    echo -e "\nBackup script successfully written to $SCRIPT_PATH"

    # cron
    echo -e "\nDo you want to schedule this backup with crontab? (y/n): "
    read -r SCHEDULE_CRON

    if [[ "$SCHEDULE_CRON" =~ ^[Yy]$ ]]
    then
        if [ -z "$CRON_ENTRY" ]
	then
            echo -e "\nNo existing cron configuration found. Opening cron setup..."
            bckp_cron_set
        fi

        if [ -n "$CRON_ENTRY" ]
	then
            (crontab -l 2>/dev/null; echo "$CRON_ENTRY bash \"$SCRIPT_PATH\"") | crontab -
            echo -e "\nCron job added successfully:"
            echo "$CRON_ENTRY bash \"$SCRIPT_PATH\""
        else
            echo -e "\nSkipping cron scheduling. No valid cron configuration provided."
        fi
    fi

        echo -e "\nAll done! The script has been generated and can be found in $SCRIPT_PATH"
	read -n 1 -s -r -p $'\nPress any key to return to the main menu...'
	clear
	return  


}

menu_header_banner() {
    clear
    echo "==========================================="
    echo "--- Interactive Backup Script Generator ---"
    echo "==========================================="
}

# Interactive menu
# f) Format (How to store it - tar, gzip, zip)
# g) Generate the Script from current config

while true
do
    # TODO: Change the promt to beter represent the actions needed
    # print_header_banner
    menu_header_banner
    PS3="Chose one of the following options: "
    options=("Show Configuration" "Sources" "Target" "History" "Format" "Shedule" "Generate Script" "Quit")

    select opt in "${options[@]}"
    do
        case "$opt" in
            "Show Configuration")
                list_curr_config
                echo -en "\nPress ENTER key to return to the menu..."; read
                break
                ;;
            "Sources") 
                bckp_srs_menu
                break
                ;;
            "Target") 
                bckp_dest_set
                break
                ;;
            "History") 
                bckp_history_menu
                break
                ;;
            "Format") 
                bckp_format_set
                break
                ;;
            "Shedule") 
                bckp_cron_set
                break
                ;;
            "Generate Script") 
                generate_script
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


































