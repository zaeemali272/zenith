#!/usr/bin/env bash
# Zenith Script: Setup Git (HTTPS or SSH)
# Configures global git settings and authentication.

# Ensure we are in the project root
if [[ ! -f "install.sh" ]]; then
    echo "❌ Please run this script from the root of the zenith repository."
    exit 1
fi

# Load UI if available for pretty logging
if [[ -f "modules/ui.sh" ]]; then
    source "modules/ui.sh"
else
    # Fallback logging
    log_step() { echo -e "\e[1;34m[STEP]\e[0m $*"; }
    log() { echo -e "  ➜ $*"; }
    log_success() { echo -e "\e[1;32m[OK]\e[0m $*"; }
    log_error() { echo -e "\e[1;31m[ERR]\e[0m $*"; }
    ask_choice() {
        local prompt=$1; shift; local options=("$@")
        echo -e "\n$prompt"
        for i in "${!options[@]}"; do echo "$((i+1))) ${options[$i]}"; done
        read -p "Select an option: " choice
        MENU_CHOICE=$((choice-1))
    }
fi

log_step "🚀 Git Configuration Setup"

options=(
    "HTTPS (Simple, uses Personal Access Token)"
    "SSH (Secure, uses SSH Keys - Recommended)"
    "Cancel"
)

ask_choice "How would you like to authenticate with GitHub?" "${options[@]}"

case $MENU_CHOICE in
    0) # HTTPS
        log_step "Configuring Git via HTTPS..."
        read -p "  ➜ Enter your Git Email: " git_email
        read -p "  ➜ Enter your Git Username: " git_user
        
        git config --global user.email "$git_email"
        git config --global user.name "$git_user"
        
        log ""
        echo -e "${BOLD}${YELLOW}🔑 INSTRUCTIONS FOR GITHUB TOKEN:${NC}"
        echo -e "1. Login to ${CYAN}github.com${NC}"
        echo -e "2. Click on your ${BOLD}Profile Picture${NC} (top right) -> ${CYAN}Settings${NC}"
        echo -e "3. Scroll to the bottom left -> ${CYAN}Developer Settings${NC}"
        echo -e "4. Click ${CYAN}Personal access tokens${NC} -> ${CYAN}Fine-grained tokens${NC}"
        echo -e "5. Click ${BOLD}Generate new token${NC}"
        echo -e "6. Give it a name, set expiration, and grant 'Contents' access to repos."
        echo -e "7. ${MAGENTA}Copy the token${NC} - you will need it when Git asks for your password."
        log ""
        
        log "Setting up credential helper (store mode)..."
        git config --global credential.helper store
        log_success "Git configured for HTTPS. Credentials will be saved permanently after your first push/pull."
        ;;

    1) # SSH
        log_step "Configuring Git via SSH..."
        read -p "  ➜ Enter your Git Email: " git_email
        read -p "  ➜ Enter your Git Username: " git_user
        
        git config --global user.email "$git_email"
        git config --global user.name "$git_user"
        
        ssh_key="$HOME/.ssh/id_ed25519"
        if [[ ! -f "$ssh_key" ]]; then
            log "Generating new SSH key (Ed25519)..."
            mkdir -p "$HOME/.ssh"
            ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""
        else
            log "SSH key already exists at $ssh_key"
        fi
        
        log "Starting ssh-agent..."
        eval "$(ssh-agent -s)"
        ssh-add "$ssh_key"
        
        log ""
        echo -e "${BOLD}${YELLOW}📋 ADD THIS KEY TO GITHUB:${NC}"
        echo -e "${CYAN}$(cat ${ssh_key}.pub)${NC}"
        log ""
        echo -e "1. Go to GitHub -> Profile -> ${CYAN}Settings${NC}"
        echo -e "2. Click ${CYAN}SSH and GPG keys${NC} -> ${BOLD}New SSH key${NC}"
        echo -e "3. Paste the key above and save."
        log ""
        log_success "Git configured for SSH. You can now use SSH URLs (git@github.com:user/repo.git)."
        ;;

    *)
        log "Git setup cancelled."
        exit 0
        ;;
esac
