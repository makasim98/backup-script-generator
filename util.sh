#!/bin/bash


# THIS is NOT a fool-proof check. It ignores possible semantic errors (Possible future upgrade)
# EX: '* * */40 * *' --> is impossible because there is no month that has a 40th day (31 max)
is_valid_cron () {
    # Convert to array of parameters
    local cron_str=$1
    IFS=' ' read -r -a cron_arr <<< "$cron_str"
    local num_fields=${#cron_arr[@]}

    # Check that it has 5 fields (* * * * *)
    if [ "$num_fields" -ne 5 ]; then
        echo "ERROR: Crons string must have 5 fields, but has $num_fields."
        return 1
    fi

    # Check for accepted characters in cron params (numbers, '*', '/', '-', ',')
    local valid_chars='^[0-9*/,\-]+$'
    for field in "${cron_arr[@]}"
    do
        if [[ ! "$field" =~ $valid_chars ]]; then
            echo "ERROR: Invalid character found in cron field: '$field'."
            return 1
        fi
    done

    # Try to install it with crontab to check for syntax errors
    local tmp_file; tmp_file=$(mktemp)
    echo "$cron_str /bin/true" > "$tmp_file"
    crontab "$tmp_file" 2>/dev/null
    local exit_code=$?
    rm "$tmp_file"

    if [ "$exit_code" -ne 0 ]; then
        echo "ERROR: Cron string '$cron_str' contains syntax errors."
        return 1
    fi

    return 0
}