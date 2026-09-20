#!/usr/bin/env bash

N=10

while true; do
    {
        date '+--- %Y-%m-%d %H:%M:%S ---'
        free -h
        df -h
        uptime
        printf '\n'
    } >> monitor.log

    sleep "$N"
done