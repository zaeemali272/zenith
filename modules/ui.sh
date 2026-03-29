#!/usr/bin/env bash

# Colors
export RED='\e[1;31m'
export GREEN='\e[1;32m'
export YELLOW='\e[1;33m'
export BLUE='\e[1;34m'
export MAGENTA='\e[1;35m'
export CYAN='\e[1;36m'
export WHITE='\e[1;37m'
export BOLD='\e[1m'
export NC='\e[0m' # No Color

export BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

STATE_FILE="$HOME/.zenith_install_state"
ERROR_LOG="$DOTS_DIR/zenith_install_error.log"
declare -A RUN_STATE

# Load existing state
if [[ -f "$STATE_FILE" ]]; then
    while IFS='=' read -r key val; do RUN_STATE["$key"]="$val"; done < "$STATE_FILE"
fi

mark_done() {
    RUN_STATE["$1"]=1
    echo "$1=1" >> "$STATE_FILE"
}

has_run() { [[ "${RUN_STATE[$1]:-0}" -eq 1 ]]; }

# UI Functions
print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "  ███████╗███████╗███╗   ██╗██╗████████╗██╗  ██╗"
    echo "  ╚══███╔╝██╔════╝████╗  ██║██║╚══██╔══╝██║  ██║"
    echo "    ███╔╝ █████╗  ██╔██╗ ██║██║   ██║   ███████║"
    echo "   ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║   ██╔══██║"
    echo "  ███████╗███████╗██║ ╚████║██║   ██║   ██║  ██║"
    echo "  ╚══════╝╚══════╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${MAGENTA}━━━━ Arch Perfection Protocol ━━━━${NC}\n"
}

log_step() {
    if [[ "${JSON_OUTPUT:-0}" == "true" || "${JSON_OUTPUT:-0}" == "1" ]]; then
        echo "{\"type\": \"task\", \"message\": \"$*\"}"
    else
        echo -e "${BLUE}${BOLD}[STEP]${NC} ${WHITE}$*${NC}"
    fi
}

log() {
    if [[ "${JSON_OUTPUT:-0}" == "true" || "${JSON_OUTPUT:-0}" == "1" ]]; then
        echo "{\"type\": \"log\", \"level\": \"info\", \"message\": \"$*\"}"
    else
        echo -e "${BLUE}  ➜${NC} ${WHITE}$*${NC}"
    fi
}

log_success() {
    if [[ "${JSON_OUTPUT:-0}" == "true" || "${JSON_OUTPUT:-0}" == "1" ]]; then
        echo "{\"type\": \"log\", \"level\": \"success\", \"message\": \"$*\"}"
    else
        echo -e "${GREEN}${BOLD}[OK]${NC} ${WHITE}$*${NC}"
    fi
}

log_warn() {
    if [[ "${JSON_OUTPUT:-0}" == "true" || "${JSON_OUTPUT:-0}" == "1" ]]; then
        echo "{\"type\": \"log\", \"level\": \"warn\", \"message\": \"$*\"}"
    else
        echo -e "${YELLOW}${BOLD}[WARN]${NC} ${YELLOW}$*${NC}"
    fi
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERR: $*" >> "$ERROR_LOG"
    if [[ "${JSON_OUTPUT:-0}" == "true" || "${JSON_OUTPUT:-0}" == "1" ]]; then
        echo "{\"type\": \"log\", \"level\": \"error\", \"message\": \"$*\"}"
    else
        echo -e "${RED}${BOLD}[ERR]${NC} ${RED}$*${NC}"
    fi
}

# Progress Bar Function
# Usage: show_progress <current> <total> <label>
show_progress() {
    local current=$1
    local total=$2
    local label=$3

    if [[ $total -eq 0 ]]; then return; fi

    if [[ "$JSON_OUTPUT" == "true" || "$JSON_OUTPUT" == "1" ]]; then
        local progress=$(awk "BEGIN {printf \"%.2f\", $current / $total}")
        echo "{\"type\": \"progress\", \"value\": $progress, \"message\": \"$label ($current/$total)\"}"
    else
        local percent=$((current * 100 / total))
        local filled=$((percent / 2))

        # Generate bar without using seq (to avoid set -e issues with 0)
        local bar=""
        for ((i=0; i<filled; i++)); do bar+="#"; done

        printf "\r${CYAN}${BOLD}[%-50s] %d%% ${WHITE}%s${NC}" "$bar" "$percent" "$label"
        if [ "$current" -eq "$total" ]; then echo -e ""; fi
    fi
}


# Interactive Menu
ask_choice() {
    local prompt=$1
    shift
    local options=("$@")
    
    if [[ "$JSON_OUTPUT" == "true" || "$JSON_OUTPUT" == "1" ]]; then
        log "Non-interactive mode: Auto-selecting first option for '$prompt'"
        MENU_CHOICE=0
        return 0
    fi

    echo -e "\n${BOLD}${CYAN}❓ $prompt${NC}"
    for i in "${!options[@]}"; do
        echo -e "  ${MAGENTA}$((i+1)))${NC} ${WHITE}${options[$i]}${NC}"
    done
    
    local choice
    while true; do
        read -p "Select an option [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            MENU_CHOICE=$((choice - 1))
            return 0
        fi
        echo -e "${RED}Invalid selection. Please try again.${NC}"
    done
}

installation_summary() {
    local type=$1
    clear
    print_header
    echo -e "${GREEN}${BOLD}✅ Zenith Installation Complete!${NC}"
    echo -e "\n${CYAN}Summary of changes:${NC}"
    echo -e "  ➜ Mode: ${WHITE}$type${NC}"
    echo -e "  ➜ User: ${WHITE}$USER${NC}"
    echo -e "  ➜ Shell: ${WHITE}$(command -v fish || echo "bash")${NC}"
    echo -e "  ➜ Environment: ${WHITE}Hyprland${NC}"
    
    if [[ "$type" == "Full" ]]; then
        echo -e "  ➜ System Tuning: ${GREEN}Applied${NC}"
        echo -e "  ➜ Dotfiles Sync: ${GREEN}Success${NC}"
        echo -e "  ➜ Services: ${GREEN}Configured${NC}"
    fi

    echo -e "\n${YELLOW}${BOLD}The system will reboot shortly to apply all changes.${NC}"
    echo -e "${WHITE}If Hyprland doesn't start automatically, log in and type 'start-hyprland'.${NC}"
}
