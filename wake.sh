# This script disables sleeping on lid close and re-enables it after a timeout or keypress.

#!/bin/bash

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
printf "\e[2mPress any key to re-enable or close the terminal...\e[0m\n"

if [[ -n $TIMEOUT ]]; then
    read -rsn 1 -t "$TIMEOUT" < /dev/tty 2>/dev/null
else
    read -rsn 1 < /dev/tty 2>/dev/null
fi

exit 0
