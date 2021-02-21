#!/bin/bash

declare SLACK_SH_DRYRUN="false"
declare -i SLACK_SH_GAME_COUNT=0
declare -i SLACK_SH_WIN_COUNT=0
declare SLACK_SH_LAST_GIT_HASH=""
declare SLACK_SH_BURGER_WAR_DEV_REPOSITORY=$HOME/catkin_ws/src/burger_war_dev
function send_slack() {
    local ITERATION="$1"
    local ENEMY_LEVEL="$2"
    local GAME_TIME="$3"
    local DATE="$4"
    local MY_SCORE="$5"
    local ENEMY_SCORE="$6"
    local BATTLE_RESULT="$7"
    local MY_SIDE="$8"
    local HOSTNAME="$(uname -n)"
    local GIT_HASH="$(git -C ${SLACK_SH_BURGER_WAR_DEV_REPOSITORY} rev-parse --short HEAD)"

    if [ -z "${SLACK_SH_WEBHOOK_URI}" ]; then
	echo "send_slack: Please set SLACK_SH_WEBHOOK_URI env var."
	return 1
    fi

    local RED="D00000"
    local GREEN="00FF00"

    if [ "${GIT_HASH}" != "${SLACK_SH_LAST_GIT_HASH}" ]; then
        SLACK_SH_GAME_COUNT=0
        SLACK_SH_WIN_COUNT=0
        SLACK_SH_LAST_GIT_HASH="${GIT_HASH}"
    fi

    let ++SLACK_SH_GAME_COUNT
    if [ "${BATTLE_RESULT}" = "WIN" ]; then
        local COLOR="${GREEN}"
        let ++SLACK_SH_WIN_COUNT
    else
        local COLOR="${RED}"
    fi

    local PAYLOAD=$(cat <<EOF
{
  "username": "autotest",
  "text": "${GIT_HASH}@${HOSTNAME} record:${SLACK_SH_WIN_COUNT}/${SLACK_SH_GAME_COUNT}",
  "attachments": [{
    "color": "${COLOR}",
    "text": "*${BATTLE_RESULT} ${MY_SCORE} vs ${ENEMY_SCORE}*\n${DATE} ${ITERATION}-${ENEMY_LEVEL}",
  }],
  "icon_emoji": ":ghost:"
}
EOF
       )

    if [ "${SLACK_SH_DRYRUN}" = "true" ]; then
        echo "${PAYLOAD}"
        return
    fi

    curl -X POST \
         -H 'Content-type: application/json' \
         --data "${PAYLOAD}" ${SLACK_SH_WEBHOOK_URI}
}

function send_slack_video() {
    if [ $# -ne 2 ]; then
	echo "${FUNCNAME[0]}: ${LINENO}: Invalid args ($*)" > /dev/stderr
	return
    fi

    local VIDEO_TITLE="$1"
    local VIDEO_ID="$2"

    local PAYLOAD=$(cat <<EOF
{
  "username": "autotest",
  "text": "<https://www.youtube.com/watch?v=${VIDEO_ID}|${VIDEO_TITLE}>",
  "icon_emoji": ":ghost:"
}
EOF
       )

    if [ "${SLACK_SH_DRYRUN}" = "true" ]; then
        echo "${PAYLOAD}"
        return
    fi

    curl -X POST \
         -H 'Content-type: application/json' \
         --data "${PAYLOAD}" ${SLACK_SH_WEBHOOK_URI}
}

# The followings are test code.
# When source this script, return here
return 1 2>/dev/null || true


function test_send_slack() {
    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 WIN r
    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 LOSE r
    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 WIN r
    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 WIN r

    if [ ${SLACK_SH_GAME_COUNT} -ne 4 ] || [ ${SLACK_SH_WIN_COUNT} -ne 3 ]; then
        echo "NG @${LINENO} GAME_COUNT=${SLACK_SH_GAME_COUNT} WIN_COUNT=${SLACK_SH_WIN_COUNT}"
        exit 1
    fi

    SLACK_SH_LAST_GIT_HASH="abcabca"

    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 WIN r
    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 LOSE r
    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 WIN r
    send_slack 0 1 300 2021-02-09T12:52:36+00:00 10 0 WIN r

    if [ ${SLACK_SH_GAME_COUNT} -ne 4 ] || [ ${SLACK_SH_WIN_COUNT} -ne 3 ]; then
        echo "NG @${LINENO} GAME_COUNT=${SLACK_SH_GAME_COUNT} WIN_COUNT=${SLACK_SH_WIN_COUNT}"
        exit 1
    fi
}

function test_send_slack_video() {
    send_slack_video "/home/ubuntu/video/20210213/GAME_2021-02-13T12:30:31+00:00_0_2_225_10_0_WIN_r.mp4" "eCa9F3UafL4"
    send_slack_video
    send_slack_video "hoge"
}

SLACK_SH_DRYRUN="true"
test_send_slack
test_send_slack_video
echo SUCCESS
