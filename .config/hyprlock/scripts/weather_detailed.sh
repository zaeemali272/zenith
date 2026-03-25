#!/bin/bash

# --- CONFIGURATION ---
cache_file="$HOME/.cache/weather.json"
expiry_time=1800 # 30 mins
ICON_ERROR="󰖪"

# --- WEATHER ---
get_weather_detailed() {
    # Check if cache exists and is fresh
    if [ -f "$cache_file" ]; then
        last_modified=$(stat -c %Y "$cache_file")
        current_date=$(date +%s)
        time_diff=$((current_date - last_modified))
        
        if [ $time_diff -ge $expiry_time ]; then
             curl -s --max-time 10 "wttr.in/?format=j1" > "$cache_file.tmp" && mv "$cache_file.tmp" "$cache_file"
        fi
    else
        curl -s --max-time 10 "wttr.in/?format=j1" > "$cache_file"
    fi

    if [ ! -s "$cache_file" ] || [[ $(cat "$cache_file") == *"Error"* ]]; then
        echo "$ICON_ERROR Weather Unavailable"
        return
    fi

    # Parse with jq
    temp=$(jq -r '.current_condition[0].temp_C' "$cache_file")
    feels=$(jq -r '.current_condition[0].FeelsLikeC' "$cache_file")
    desc=$(jq -r '.current_condition[0].weatherDesc[0].value' "$cache_file")
    hum=$(jq -r '.current_condition[0].humidity' "$cache_file")
    wind_km=$(jq -r '.current_condition[0].windspeedKmph' "$cache_file")
    wind_dir=$(jq -r '.current_condition[0].winddir16Point' "$cache_file")
    # precip=$(jq -r '.current_condition[0].precipMM' "$cache_file")
    pressure=$(jq -r '.current_condition[0].pressure' "$cache_file")
    uv=$(jq -r '.current_condition[0].uvIndex' "$cache_file")
    cloud=$(jq -r '.current_condition[0].cloudcover' "$cache_file")
    rain_chance=$(jq -r '.weather[0].hourly[0].chanceofrain' "$cache_file")
    
    icon="" # Default
    case "$desc" in
        "Sunny"|"Clear") icon="󰖙" ;;
        "Partly cloudy") icon="󰖕" ;;
        "Cloudy") icon="󰖐" ;;
        "Overcast") icon="󰖐" ;;
        "Mist"|"Fog") icon="󰖑" ;;
        "Smoke") icon="󰖑" ;;
        "Patchy rain possible"|"Patchy light rain"|"Light rain") icon="󰖗" ;;
        "Light rain shower") icon="󰖗" ;;
        "Moderate rain"|"Heavy rain") icon="󰖖" ;;
        "Thundery outbreaks possible") icon="󰖓" ;;
        *) 
           if [[ "$desc" == *"rain"* ]]; then icon="󰖖"; 
           elif [[ "$desc" == *"snow"* ]]; then icon="󰼶"; 
           elif [[ "$desc" == *"storm"* ]]; then icon="󰖓"; 
           fi
           ;;
    esac

    # Building the output
    echo "$icon $desc"
    echo "󰔄 Temp  : $temp°C ($feels°C)"
    echo "󰖃 Humid : $hum%"
    echo "󰖐 Cloud : $cloud%"
    echo "󰖝 Wind  : $wind_km km/h"
    echo "󰖗 Rain  : $rain_chance%"
}

get_weather_detailed
