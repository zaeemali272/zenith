#!/usr/bin/env bash

ACTION="$1"
DIR="$2"

send_notify() {
    notify-send \
        -t 1000 \
        -h "int:value:$1" \
        -h "string:x-canonical-private-synchronous:$2" \
        -h "string:category:$2" \
        "$3"
}

case "$ACTION" in
brightness)
    STEP=2

    CUR_RAW=$(brightnessctl get)
    MAX=$(brightnessctl max)
    CUR=$(( CUR_RAW * 100 / MAX ))

    case "$DIR" in
        up)
            if (( CUR == 0 )); then
                brightnessctl set +1%
            else
                brightnessctl set +${STEP}%
            fi
            ;;
        down)
            if (( CUR == 2 )); then
                brightnessctl set 1%
            elif (( CUR == 1 )); then
                brightnessctl set 0%
            else
                brightnessctl set ${STEP}%-
            fi
            ;;
    esac

    CUR_RAW=$(brightnessctl get)
    CUR=$(( CUR_RAW * 100 / MAX ))

    if (( CUR <= 33 )); then icon="🔅"
    elif (( CUR <= 66 )); then icon="☀️"
    else icon="🔆"
    fi

    send_notify "$CUR" brightness "$icon  Brightness ${CUR}%"
    ;;

volume)
    STEP=3

    STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    VOL=$(awk '{print int($2 * 100)}' <<<"$STATUS")
    MUTED=$(grep -q MUTED <<<"$STATUS" && echo 1 || echo 0)

    case "$DIR" in
        up)
            if (( MUTED )); then
                wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%
            else
                wpctl set-volume @DEFAULT_AUDIO_SINK@ ${STEP}%+
            fi
            ;;
        down)
            if (( VOL > 1 && VOL <= 3 )); then
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%
            elif (( VOL == 1 )); then
                wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
                wpctl set-volume @DEFAULT_AUDIO_SINK@ 0%
            else
                wpctl set-volume @DEFAULT_AUDIO_SINK@ ${STEP}%-
            fi
            ;;
        mute)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            ;;
    esac

    STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    VOL=$(awk '{print int($2 * 100)}' <<<"$STATUS")

    if grep -q MUTED <<<"$STATUS"; then
        icon=""
        text="Muted"
        VOL=0
    else
        (( VOL == 0 )) && icon="  "
        (( VOL <= 30 )) && icon="  "
        (( VOL > 30 )) && icon="  "
        text="Volume ${VOL}%"
    fi

    send_notify "$VOL" volume "$icon  $text"
    ;;
esac

