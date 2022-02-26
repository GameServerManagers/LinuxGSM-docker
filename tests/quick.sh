#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."

# shellcheck source=tests/internal/api_docker.sh
source "$(dirname "$0")/internal/api_docker.sh"
# shellcheck source=tests/internal/api_various.sh
source "$(dirname "$0")/internal/api_various.sh"
# shellcheck source=tests/steam_test_credentials
source "$(dirname "$0")/steam_test_credentials"



LOGS="false"
LOG_DEBUG="false"
DEBUG="false"
IMAGE="gameservermanagers/linuxgsm-docker"
RETRY="1"
GAMESERVER=""

build=(./internal/build.sh)
run=(./internal/run.sh)
while [ $# -ge 1 ]; do
    key="$1"
    shift

    case "$key" in
        -h|--help)
            echo "[help][quick] quick testing of provided gameserver"
            echo "[help][quick] quick.sh [option] server"
            echo "[help][quick] "
            echo "[help][quick] options:"
            echo "[help][quick] -c  --no-cache      run without docker cache"
            echo "[help][quick] -d  --debug         run gameserver and overwrite entrypoint to bash"
            echo "[help][quick]     --image      x  target image"
            echo "[help][quick] -l  --logs          print complete docker log afterwards"
            echo "[help][quick]     --log-debug     enables LGSM_DEBUG, log can contain your steam credentials, dont share it!"
            echo "[help][quick]     --retry         if run failed, rebuild and rerun up to 3 times"
            echo "[help][quick]     --skip-lgsm     skip build lgsm"
            echo "[help][quick]     --very-fast     overwrite healthcheck, only use it with volumes / lancache because container will else fail pretty fast"
            echo "[help][quick]     --version    x  use linuxgsm version x e.g. \"v21.4.1\""
            echo "[help][quick]     --volume     x  use volume x e.g. \"lgsm\""
            echo "[help][quick] "
            echo "[help][quick] server            e.g. gmodserver"
            exit 0;;
        -c|--no-cache)
            build+=(--no-cache);;
        -d|--debug)
            run+=(--debug)
            DEBUG="true";;
        --image)
            IMAGE="$1"
            shift;;
        -l|--logs)
            LOGS="true";;
        --log-debug)
            LOG_DEBUG="true";;
        --retry)
            RETRY="3";;
        --skip-lgsm)
            build+=(--skip-lgsm);;
        --suffix)
            build+=(--suffix "$1")
            run+=(--suffix "$1" )
            shift;;
        --very-fast)
            run+=(--quick);;
        --version)
            build+=(--version "$1")
            shift;;
        --volume)
            run+=(--volume "$1")
            shift;;
        *)
            if [ -z "$GAMESERVER" ]; then
                GAMESERVER="$key"
            else
                echo "[info][quick] additional argument to docker: \"$key\""
                run+=("$key")
            fi;;
    esac
done

if [ -z "$GAMESERVER" ]; then
    echo "[error][quick] no gameserver provided"
    exit 1
elif grep -qEe "(^|\s)$GAMESERVER(\s|$)" <<< "${credentials_enabled[@]}"; then
	echo "[info][quick] $GAMESERVER can only be tested with steam credential"
	if [ -n "$steam_test_username" ] && [ -n "$steam_test_password" ]; then
    	run+=(-e CONFIGFORCED_steamuser="$steam_test_username" -e CONFIGFORCED_steampass="$steam_test_password")
	else
		echo "[error][quick] $GAMESERVER can only be tested with steam credentials, please fill $(realpath "$(dirname "$0")/steam_test_credentials")"
		exit 2
	fi
else
    echo "[warning][quick] no steam credentials provided, some servers will fail without it"
fi

CONTAINER="linuxgsm-$GAMESERVER"
build+=(--image "$IMAGE" --latest "$GAMESERVER")
run+=(--image "$IMAGE" --tag "$GAMESERVER" --container "$CONTAINER")
if ! "$DEBUG"; then
    run+=(--detach)
fi
if "$LOG_DEBUG"; then
    run+=(-e LGSM_DEBUG="true")
fi

function handleInterrupt() {
    removeContainer "$CONTAINER"
}
trap handleInterrupt SIGTERM SIGINT

(
    cd "$(dirname "$0")"
    successful="false"
    try="1"
    while [ "$try" -le "$RETRY" ] && ! "$successful"; do
        echo "[info][quick] try $try"
        try="$(( try+1 ))"
        removeContainer "$CONTAINER"
        echo "${build[@]}"
        "${build[@]}"
        echo "${run[@]}" | sed -E 's/(steamuser|steampass)=\S+/\1="xxx"/g'
        "${run[@]}"

        if "$DEBUG" || awaitHealthCheck "$CONTAINER"; then
            successful="true"
        fi
        
        echo ""
        echo "[info][quick] printing dev-debug-function-order.log"
        docker exec -it "$CONTAINER" cat "dev-debug-function-order.log" || true
        stty sane
        echo ""
        echo "[info][quick] printing dev-debug.log"
        docker exec -it "$CONTAINER" cat "dev-debug.log" || true
        echo ""
        stty sane
        
        stopContainer "$CONTAINER"
        if "$LOGS"; then
            printf "[info][quick] logs:\n%s\n" "$(docker logs "$CONTAINER" 2>&1 || true)"
        elif ! "$successful"; then
            printf "[info][quick] logs:\n%s\n" "$(docker logs -n 20 "$CONTAINER" 2>&1 || true)"
        fi
        printf "[info][quick] healthcheck log:\n%s\n" "$(docker inspect -f '{{json .State.Health.Log}}' "$CONTAINER" | jq | sed 's/\\r/\n/g' | sed 's/\\n/\n/g' || true)"
        
    done
    removeContainer "$CONTAINER"

    if "$successful"; then
        echo "[info][quick] successful"
        exit 0
    else
        echo "[error][quick] failed"
        exit 1
    fi
)
