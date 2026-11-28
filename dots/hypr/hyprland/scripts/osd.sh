#!/usr/bin/env bash
export PATH="/etc/profiles/per-user/${USER:-$(id -un)}/bin:/run/current-system/sw/bin:$HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"

ACTION="${1:-}"
DIR="${2:-}"

send_notify() {
    local val="$1" tag="$2" msg="$3"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send \
            -t 1000 \
            -h "int:value:$val" \
            -h "string:x-canonical-private-synchronous:$tag" \
            -h "string:category:$tag" \
            "$msg" 2>/dev/null || true
    fi
}

case "$ACTION" in
brightness)
    STEP=5
    # Find sysfs backlight path if available
    SYSFS_BACKLIGHT=""
    for b in /sys/class/backlight/*; do
        if [ -d "$b" ]; then
            SYSFS_BACKLIGHT="$b"
            break
        fi
    done

    # Target display backlight class explicitly if available, otherwise default device
    DEV_FLAG=""
    if brightnessctl -c backlight info >/dev/null 2>&1; then
        DEV_FLAG="-c backlight"
    fi

    CUR_RAW=$(brightnessctl $DEV_FLAG get 2>/dev/null || echo 0)
    MAX=$(brightnessctl $DEV_FLAG max 2>/dev/null || echo 100)
    if (( MAX <= 0 )); then
        if [ -n "$SYSFS_BACKLIGHT" ] && [ -r "$SYSFS_BACKLIGHT/max_brightness" ]; then
            MAX=$(cat "$SYSFS_BACKLIGHT/max_brightness")
        else
            MAX=100
        fi
    fi

    CUR=$(( (CUR_RAW * 100 + MAX / 2) / MAX ))

    set_backlight_perc() {
        local target_perc="$1"
        (( target_perc < 1 )) && target_perc=1
        (( target_perc > 100 )) && target_perc=100
        if [ -n "$SYSFS_BACKLIGHT" ]; then
            local dev_name raw sid spath
            dev_name="$(basename "$SYSFS_BACKLIGHT")"
            raw=$(( (target_perc * MAX + 50) / 100 ))
            (( raw < 1 )) && raw=1
            if [ -w "$SYSFS_BACKLIGHT/brightness" ] && echo "$raw" > "$SYSFS_BACKLIGHT/brightness" 2>/dev/null; then
                return 0
            fi
            sid="$(loginctl list-sessions --no-legend 2>/dev/null | awk '$4 != "-" && $4 != "" {print $1; exit}')"
            [ -n "$sid" ] || sid="$(loginctl list-sessions --no-legend 2>/dev/null | awk '{print $1; exit}')"
            if [ -n "$sid" ]; then
                spath="$(busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager GetSession s "$sid" 2>/dev/null | awk '{print $2}' | tr -d '"')"
                if [ -n "$spath" ]; then
                    busctl call org.freedesktop.login1 "$spath" org.freedesktop.login1.Session SetBrightness ssu backlight "$dev_name" "$raw" >/dev/null 2>&1 && return 0
                fi
            fi
        fi
        return 1
    }

    case "$DIR" in
        up)
            NEW_PERC=$(( CUR + STEP ))
            if (( NEW_PERC > 100 )); then NEW_PERC=100; fi
            if (( CUR == 0 && CUR_RAW == 0 )); then
                brightnessctl $DEV_FLAG set 1% >/dev/null 2>&1 || true
            fi
            if ! brightnessctl $DEV_FLAG set "+${STEP}%" >/dev/null 2>&1; then
                set_backlight_perc "$NEW_PERC" || true
            fi
            ;;
        down)
            NEW_PERC=$(( CUR - STEP ))
            if (( NEW_PERC < 1 )); then NEW_PERC=1; fi
            if (( CUR <= STEP )); then
                if ! brightnessctl $DEV_FLAG set 1% >/dev/null 2>&1; then
                    set_backlight_perc 1 || true
                fi
            else
                if ! brightnessctl $DEV_FLAG set "${STEP}%-" >/dev/null 2>&1; then
                    set_backlight_perc "$NEW_PERC" || true
                fi
            fi
            ;;
    esac

    CUR_RAW=$(brightnessctl $DEV_FLAG get 2>/dev/null || echo 0)
    if [ -n "$SYSFS_BACKLIGHT" ] && [ -r "$SYSFS_BACKLIGHT/actual_brightness" ]; then
        CUR_RAW=$(cat "$SYSFS_BACKLIGHT/actual_brightness" 2>/dev/null || echo "$CUR_RAW")
    fi
    CUR=$(( (CUR_RAW * 100 + MAX / 2) / MAX ))

    if (( CUR <= 33 )); then
        icon="🔅"
    elif (( CUR <= 66 )); then
        icon="☀️"
    else
        icon="🔆"
    fi

    send_notify "$CUR" brightness "$icon  Brightness ${CUR}%"
    ;;

volume)
    STEP=3
    STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.00")
    VOL=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+$/) {print int($i*100+0.5); exit}}' <<<"$STATUS")
    VOL="${VOL:-0}"
    MUTED=$(grep -q MUTED <<<"$STATUS" && echo 1 || echo 0)

    case "$DIR" in
        up)
            if (( MUTED )); then
                wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null || true
            fi
            wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "${STEP}%+" 2>/dev/null || true
            ;;
        down)
            wpctl set-volume @DEFAULT_AUDIO_SINK@ "${STEP}%-" 2>/dev/null || true
            ;;
        mute)
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle 2>/dev/null || true
            ;;
    esac

    STATUS=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.00")
    VOL=$(awk '{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.[0-9]+$/) {print int($i*100+0.5); exit}}' <<<"$STATUS")
    VOL="${VOL:-0}"

    if grep -q MUTED <<<"$STATUS"; then
        send_notify 0 volume "  Muted"
    else
        if (( VOL == 0 )); then
            icon=""
        elif (( VOL <= 30 )); then
            icon=""
        else
            icon=""
        fi
        send_notify "$VOL" volume "$icon  Volume ${VOL}%"
    fi
    ;;
esac