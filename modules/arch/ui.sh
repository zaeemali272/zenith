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

# Steps that failed on a previous run, so a rerun can retry exactly those.
FAILED_FILE="$HOME/.zenith_install_failed"
declare -a STEPS_RUN=() STEPS_SKIPPED=() STEPS_FAILED=()

mark_done() {
    RUN_STATE["$1"]=1
    # Rewrite rather than append: this file was only ever appended to, so a few
    # reruns left it full of duplicate lines.
    { grep -v "^$1=" "$STATE_FILE" 2>/dev/null; echo "$1=1"; } > "$STATE_FILE.tmp" \
        && mv "$STATE_FILE.tmp" "$STATE_FILE"
    sed -i "/^$1$/d" "$FAILED_FILE" 2>/dev/null || true
}

mark_failed() {
    RUN_STATE["$1"]=0
    grep -qx "$1" "$FAILED_FILE" 2>/dev/null || echo "$1" >> "$FAILED_FILE"
}

has_run() { [[ "${RUN_STATE[$1]:-0}" -eq 1 ]]; }

# run_step <id> <description> <command...>
#
# The point of this is that rerunning the installer after a failure fixes what
# broke instead of repeating everything. has_run() existed but was never called
# anywhere, so state was written and never read: every rerun redid every step,
# including the ones that overwrite system configuration.
#
# A step that fails does not abort the run. It is recorded, the installer keeps
# going, and the summary at the end says what to rerun.
run_step() {
    local id="$1" desc="$2"; shift 2

    if has_run "$id" && [[ "${ZENITH_FORCE:-0}" -ne 1 ]]; then
        echo -e "  ${GREEN}✓${NC} $desc ${CYAN}(already done)${NC}"
        STEPS_SKIPPED+=("$id")
        return 0
    fi

    log_step "$desc"

    # Captured explicitly. Reading $? after an `if` block gives the status of
    # the block, not of the command -- which reported every failure as "exit 0".
    local rc=0
    "$@" || rc=$?

    if [[ $rc -eq 0 ]]; then
        mark_done "$id"
        STEPS_RUN+=("$id")
        return 0
    fi

    mark_failed "$id"
    STEPS_FAILED+=("$id")
    log_error "$desc failed (exit $rc). Continuing; rerun the installer to retry just this."
    echo "[$(date '+%F %T')] step failed: $id ($desc) exit=$rc" >> "$ERROR_LOG"
    return 0
}

# What a rerun would do, without doing anything.
show_status() {
    print_header 2>/dev/null || true
    echo -e "${BOLD}Installer state${NC}"
    echo
    if [[ -s "$STATE_FILE" ]]; then
        echo -e "  ${GREEN}completed:${NC}"
        sed 's/=1$//' "$STATE_FILE" | sort -u | sed 's/^/    /'
    else
        echo "  nothing completed yet"
    fi
    echo
    if [[ -s "$FAILED_FILE" ]]; then
        echo -e "  ${RED}failed, will be retried on the next run:${NC}"
        sort -u "$FAILED_FILE" | sed 's/^/    /'
    else
        echo -e "  ${GREEN}no failed steps${NC}"
    fi
    echo
    echo "  state:  $STATE_FILE"
    echo "  rerun:  ./install.sh              retries only what is missing or failed"
    echo "          ./install.sh --force      redo everything"
    echo "          ./install.sh --reset      forget all state"
}

print_summary() {
    echo
    echo -e "${BOLD}Summary${NC}"
    [[ ${#STEPS_RUN[@]}     -gt 0 ]] && echo -e "  ${GREEN}ran:${NC}     ${STEPS_RUN[*]}"
    [[ ${#STEPS_SKIPPED[@]} -gt 0 ]] && echo -e "  ${CYAN}skipped:${NC} ${#STEPS_SKIPPED[@]} already done"
    if [[ ${#STEPS_FAILED[@]} -gt 0 ]]; then
        echo -e "  ${RED}failed:${NC}  ${STEPS_FAILED[*]}"
        echo
        echo -e "  ${YELLOW}Rerun ./install.sh to retry just those. Nothing else will be redone.${NC}"
        echo -e "  Details: $ERROR_LOG"
        return 1
    fi
    echo -e "  ${GREEN}Everything completed.${NC}"
    return 0
}

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

log_info() {
    log "$*"
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
        read -p "Select an option [1-${#options[@]}]: " choice </dev/tty
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
