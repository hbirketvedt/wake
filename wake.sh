#!/bin/bash
# This script disables sleeping on lid close and re-enables it after a timeout or keypress.

SUDO=""
(( $EUID > 0 )) && SUDO="sudo -n"

function finish {
    ret=$?
    $SUDO pmset disablesleep 0
    printf "\nSleep \e[32menabled\e[0m\n"
    exit $ret
}

# Trap all relevant signals and ensure cleanup
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 131' QUIT
trap 'exit 143' TERM
trap finish EXIT

# Handle input argument (optional timeout in hours)
if [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]]; then
    HOURS=$1
    TIMEOUT=$(( HOURS * 3600 ))
    timeout_msg=" for $HOURS hour(s)"
else
    TIMEOUT=""
    timeout_msg=""
fi

# Disable sleep
$SUDO pmset disablesleep 1 || exit 1
printf "Sleep \e[31mdisabled\e[0m$timeout_msg\n\e[2mPress any key to re-enable or close the terminal...\e[0m\n"

# Make a named pipe for synchronization
PIPE=$(mktemp -u)
mkfifo "$PIPE"

# 1) Listen for keypress from /dev/tty in the background
{
    # Force read from actual TTY, preventing an immediate EOF
    read -rsn1 < /dev/tty
    echo "key" > "$PIPE"
} &

# 2) Also allow an optional timeout
if [[ -n $TIMEOUT ]]; then
    {
        sleep "$TIMEOUT"
        echo "timeout" > "$PIPE"
    } &
fi

# Block until either keypress or timeout arrives
read -r _ < "$PIPE"
rm -f "$PIPE"
exit 0
