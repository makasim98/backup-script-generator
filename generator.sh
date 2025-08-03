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

add_bckp_src() {
    echo "--- Setting Source Directory to Backup ---"
    while true
    do
        read -e -p "Enter the full source path of the directory to backup (e.g., /home/user/folder) OR enter 'done' when done: " src

        if [[ "$src" == "done" ]]
        then
            if [ ${#SOURCE_PATHS[@]} -eq 0 ]
            then
                echo "ERROR: No source directories have been added."
                return
            else
                echo "Source directories added successfully."
                break
            fi
        fi

        if [ -d "$src" ]
        then
            SOURCE_PATHS+=("$src")
            echo "SUCCESS: Source directory '$src' added to the backup list."
        else
            echo "ERROR: '$src' is not a valid directory."
        fi
    done
}

get_max_history() {
    echo "=============================="
    echo "--- Setting Backup Frequency Configurations ---"
    
    while true
    do
        # TODO: Change the promt to beter represent the actions needed
        local PS3="Chose one of the following options: "
        local options=("Max Backup Number" "Back")

        select opt in "${options[@]}"
        do
            case "$opt" in
                "Max Backup Number") 
                    read -p "How many backup instances do you want to keep at the time (default: 1): " bckp_num
                    if [[ "$bckp_num" =~ ^[0-9]+$ ]] && [ "$bckp_num" -gt 0 ]; then 
                        BCKP_HISTORY_MAX_NUM=$bckp_num
                        echo -e "SUCCESS: Maximum number of backup instances is set to $bckp_num."
                    else
                        echo -e "ERROR: Provided quantity '$bckp_num' is not a positive integer."
                    fi
                    break
                    ;;
                "Back") 
                    return
                    ;;
                *)
                    echo "Invalid option: Try Again!"
                    ;;
            esac
        done
    done 
}

# TODO: test that the utility is installed before assigning the format
get_bckp_format() {
    echo "--- Setting Backup Format ---"

    local PS3="Choose a backup format: "
    local options=("tar" "tar.gz (gzip)" "zip" "Back")

    select opt in "${options[@]}"
    do
	    case "$opt" in
		    "tar")
			    FORMAT="tar"
			    echo "SUCCESS: Backup format set to 'tar'."
			    break;;
		    "tar.gz (gzip)")
			    FORMAT="tar.gz"
			    echo "SUCCESS Backup format set to 'tar.gz'."
			    break;;
	 	    "zip")
			    FORMAT="zip"
			    echo "SUCCESS: Backup format set to 'zip'."
			    break;;
		    "Back")
			    return;;
		    *)
			    echo "Invalid option: Please try again.";;
	    esac
    done

}

add_bckp_target() {
    echo "--- Setting Backup Destination ---"
    read -e -p "Enter the full destination path where your backups will be stored (e.g., /mnt/backups): " target

    # Check if the target path is empty
    if [ -z "$target" ]; then
        echo "ERROR: Destination path cannot be empty. No changes made."
        return
    fi

    # Check if provided path exists and user has write permissions
    if [ -d "$target" ]; then
        # The directory exists, so we just need to check for write permissions
        if [ ! -w "$target" ]; then
            echo "ERROR: User '$USER' does not have write permissions to existing directory '$target'. No changes made."
            return
        fi
        
    # If dir does not extist, recusively check closest existing parent folder to confirm user permissions
    else
        path_to_check="$target"

        # Loop up the directory tree to find the nearest existing directory
        while [ ! -d "$path_to_check" ] && [ "$path_to_check" != "/" ]; do
            path_to_check=$(dirname "$path_to_check")
        done

        # Check if we have write permissions in the directory
        if [ ! -w "$path_to_check" ]; then
            echo "ERROR: User '$USER' (you) does not have write permissions in '$path_to_check' to create '$target'. No changes made."
            return
        fi
    fi

    BACKUP_DESTINATION="$target"
    echo "SUCCESS: Backup destination set to '$target'."
    echo "Note: Write permissions confirmed, no issues if backed-up by '$USER' user"
}

get_bckp_freq() {
    echo "--- Setting Backup Frequency (Shedule) ---"
    read -p "Enter the shedule the backups will follow (e.g. '* * * * *'): " cron_shed 

    if [ -z "$cron_shed" ]; then
        echo "ERROR: The provided cron shedule cannot be empty. No changes made."
        return
    fi

    if is_valid_cron "$cron_shed"; then
        CRON_ENTRY="$cron_shed"
        echo "SUCCESS: Shedule set to '$cron_shed'."
    fi
}

# TODO: Write a Detailed Help section for each choise of the main menu
help() {
    echo "HELP"
    generate_script_configs "${SOURCE_PATHS[@]}" "$BACKUP_DESTINATION" "$BCKP_HISTORY_MAX_NUM" $FORMAT
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

    echo -e "BACKUP_DESTINATION: $BACKUP_DESTINATION"
    echo -e "BACKUP FORMAT: $FORMAT"

    echo -e "CRON SHEDULE: $CRON_ENTRY"
    echo -e "MAX NUMBER OF BACKUPS: $BCKP_HISTORY_MAX_NUM"
}

generate_script() {
    # Check that all required Configs are set
    if [ ${#SOURCE_PATHS[@]} -eq 0 ]; then
        echo "ERROR: No source directories have been added."
        return
    elif [ -z "$BACKUP_DESTINATION" ]; then
       echo "ERROR: No destination path provided."
       return 
    elif [ -z "$FORMAT" ]; then
        echo "ERROR: No archiving format provided."
        return 
    fi

    echo "========== Generating Script =========="
    echo ""
    list_curr_config

    ##### GENERATE THE SCRIPT HERE #####

    BACKUP_SCRIPT_CONTENT=$(generate_script_header)
    BACKUP_SCRIPT_CONTENT+=$(generate_script_configs "${SOURCE_PATHS[@]}" "$BACKUP_DESTINATION" "$BCKP_HISTORY_MAX_NUM" $FORMAT)
    BACKUP_SCRIPT_CONTENT+=$(generate_script_body)

    ##### GENERATION FINISHED #####

    echo "$BACKUP_SCRIPT_CONTENT" > "output.sh"
    chmod +x "output.sh"  


}

print_header_banner() {
    clear
    echo "============================================="
    echo "Welcome to your interactive backup system"
    echo "============================================="
}

# Interactive menu
# f) Format (How to store it - tar, gzip, zip)
# g) Generate the Script from current config

print_header_banner
while true
do
    # TODO: Change the promt to beter represent the actions needed
    # print_header_banner
    PS3="Chose one of the following options: "
    options=("Show Configuration" "Sources" "Target" "Frequency" "History" "Format" "Generate Script" "Help" "Quit")

    select opt in "${options[@]}"
    do
        case "$opt" in
            "Show Configuration")
                list_curr_config
                echo -en "\nPress ENTER key to return to the menu..."; read
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


































