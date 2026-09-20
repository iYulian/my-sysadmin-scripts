#!/usr/bin/env bash

N=10
LOG_FILE="$(pwd)/monitor.log"

if [ ! -e "$LOG_FILE" ]; then
    printf 'Файл %s отсутствует.\n' "$LOG_FILE"

    if touch "$LOG_FILE"; then
        printf 'Файл создан: %s\n' "$LOG_FILE"
    else
        printf 'Ошибка: не удалось создать файл %s\n' "$LOG_FILE" >&2
        exit 1
    fi
fi

while true; do
    {
        date '+--- %Y-%m-%d %H:%M:%S ---'
        free -h
        df -h
        uptime
        printf '\n'
    } >> "$LOG_FILE"

    sleep "$N"
done