#!/bin/bash

# This script disables sleeping on lid close and re-enables it after a timeout,
# keypress, or (with -c) 30 continuous seconds on battery power.

if (( EUID == 0 )); then
    PMSET=(/usr/bin/pmset)
else
    PMSET=(sudo -n /usr/bin/pmset)
fi

sleep_disabled=0

finish() {
    ret=$?
    trap - EXIT

    if (( sleep_disabled )); then
        "${PMSET[@]}" disablesleep 0
        printf "\nSleep \e[32menabled\e[0m\n"
    fi

    exit "$ret"
}

trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 131' QUIT
trap 'exit 143' TERM
trap finish EXIT

cancel_on_battery=0
if [[ ${1-} == -c ]]; then
    cancel_on_battery=1
    shift
fi

if [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]]; then
    HOURS=$1
    TIMEOUT=$((HOURS * 3600))
    timeout_msg=" for $HOURS hour(s)"
else
    TIMEOUT=""
    timeout_msg=""
fi

"${PMSET[@]}" disablesleep 1 || exit 1
sleep_disabled=1

printf "Sleep \e[31mdisabled\e[0m%s\n" "$timeout_msg"
if (( cancel_on_battery )); then
    printf "Sleep will be re-enabled after 30 continuous seconds on battery power.\n"
fi
printf "\e[2mPress any key to re-enable or close the terminal...\e[0m\n"

if (( cancel_on_battery )); then
    POWER_LOSS_GRACE=30
    start_time=$SECONDS
    battery_since=""

    while :; do
        power_state=$(/usr/bin/pmset -g batt)

        if [[ $power_state == *"'Battery Power'"* ]]; then
            if [[ -z $battery_since ]]; then
                battery_since=$SECONDS
            elif (( SECONDS - battery_since >= POWER_LOSS_GRACE )); then
                printf "\nAC power has been absent for %d seconds.\n" "$POWER_LOSS_GRACE"
                break
            fi
        else
            battery_since=""
        fi

        if [[ -n $TIMEOUT ]] && (( SECONDS - start_time >= TIMEOUT )); then
            break
        fi

        read -rsn 1 -t 1 < /dev/tty 2>/dev/null
        read_status=$?
        if (( read_status < 128 )); then
            break
        fi
    done
elif [[ -n $TIMEOUT ]]; then
    read -rsn 1 -t "$TIMEOUT" < /dev/tty 2>/dev/null
else
    read -rsn 1 < /dev/tty 2>/dev/null
fi

exit 0
