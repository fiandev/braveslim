#!/bin/bash
# ==============================================================================
# Script Name: Brave Browser Privacy & Debloat
# Description:
#   Enhances Brave Browser privacy by disabling telemetry, bloatware, and
#   unwanted features. Supports Flatpak, Debian, Arch, Fedora, openSUSE, and others.
#
# Usage:
#   chmod +x main.sh
#   ./main.sh
#
# Author: Fiandev
# ==============================================================================

# ==============================================================================
# Configuration & Constants
# ==============================================================================

# Colors for terminal output
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Global State Variables
IS_ROOT=false
IS_FLATPAK=false
IS_DEBIAN=false
IS_ARCH=false
IS_FEDORA=false
IS_SUSE=false
JQ_AVAILABLE=false
DISABLE_BRAVE_AI=""

BRAVE_EXEC=""
BRAVE_DIR=""
PROFILE_DIR=""
DEFAULT_PROFILE="Default"
BACKUP_DIR=""

# Feature Lists
# ------------------------------------------------------------------------------
# List of base features to disable via command-line flags
readonly BASE_DISABLED_FEATURES=(
    BraveRewards
    BraveAds
    BraveWallet
    BraveNews
    Speedreader
    BraveAdblock
    BraveSpeedreader
    BraveVPN
    Crypto
    CryptoWallets
    InterestCohortAPI
    Fledge
    Topics
    InterestFeedV2
    UseChromeOSDirectVideoDecoder
)

# List of AI-specific features to disable if requested
readonly AI_DISABLED_FEATURES=(
    BraveLeo
    BraveLeoInline
    BraveAIChat
    BraveAIPrompts
    BravePromptAutocomplete
)

# List of domains to block in /etc/hosts for telemetry prevention
readonly HOSTS_ENTRIES=(
    "0.0.0.0 variations.brave.com"
    "0.0.0.0 go-updater.brave.com"
    "0.0.0.0 componentupdater.brave.com"
    "0.0.0.0 crlsets.brave.com"
    "0.0.0.0 laptop-updates.brave.com"
    "0.0.0.0 brave-core-ext.s3.brave.com"
    "0.0.0.0 grant.rewards.brave.com"
    "0.0.0.0 stats.brave.com"
    "0.0.0.0 p3a.brave.com"
    "0.0.0.0 analytics.brave.com"
    "0.0.0.0 rewards.brave.com"
    "0.0.0.0 pcdn.brave.com"
    "0.0.0.0 static1.brave.com"
    "0.0.0.0 updates.bravesoftware.com"
)

# ==============================================================================
# Logging Helper Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Function: log_info
# Description: Prints an informational message in green.
# Arguments:
#   $1 - Message string
# ------------------------------------------------------------------------------
log_info() { echo -e "${GREEN}$1${NC}"; }

# ------------------------------------------------------------------------------
# Function: log_warn
# Description: Prints a warning message in yellow.
# Arguments:
#   $1 - Message string
# ------------------------------------------------------------------------------
log_warn() { echo -e "${YELLOW}$1${NC}"; }

# ------------------------------------------------------------------------------
# Function: log_error
# Description: Prints an error message in red.
# Arguments:
#   $1 - Message string
# ------------------------------------------------------------------------------
log_error() { echo -e "${RED}$1${NC}"; }

# ------------------------------------------------------------------------------
# Function: log_section
# Description: Prints a section header in blue to separate script stages.
# Arguments:
#   $1 - Section title
# ------------------------------------------------------------------------------
log_section() { echo -e "\n${BLUE}$1${NC}"; }

# ==============================================================================
# System Detection Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Function: check_root
# Description: Checks if the script is running with root privileges.
# Sets global: IS_ROOT
# ------------------------------------------------------------------------------
check_root() {
    if [ "$EUID" -eq 0 ]; then
        IS_ROOT=true
    fi
}


banner () {
    echo -e "${YELLOW}
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠖⠃⠀⠀⠀⡁⠀⠀⠀⠀⠀⠐⠆⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡠⢔⡤⠊⠁⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⠀⠀⠁⠀⠀⠘⠁⢀⠀⠀⠀⠀⢈⠓⠂⠠⡄⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣶⠿⠞⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠒⠁⠀⠠⡚⠁⢀⣙⣀⣈⡩⠬⢁⠀⢑⠶⠤⡆⠤⡀⠀⠀⠀⠀⠀⠀⢀⠴⢲⣋⣽⣷⠟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⠀⢠⠀⠀⣶⠃⠗⣡⣶⣮⣿⡿⠿⠿⢿⣿⣷⣶⣤⣤⠤⠴⠦⠬⣤⣤⠄⣉⠉⠝⢲⣿⡷⠻⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠁⡀⡸⠁⣰⣿⡿⠛⠋⣁⡀⠤⠤⢄⡀⠈⠛⢯⣿⣟⣾⣶⣶⣮⣭⣵⣾⣿⣟⠿⠉⢨⠖⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⢠⠳⡧⣻⡿⠋⢀⠒⠉⠀⠀⠀⠀⠀⠀⠉⠢⠀⠀⠙⠛⣻⣿⣿⣿⢿⣿⣿⠟⡱⠖⠊⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⢠⣧⠓⣾⣿⠁⠀⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢦⣠⣾⣿⠿⣿⣿⣿⡿⣫⠏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠂⢃⣸⣿⠇⢠⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣿⠟⢿⠁⠸⡿⣿⣯⡶⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠁⢘⡄⠘⣿⣿⠀⠸⡀⠀⠀⠀⠀⠀⢀⣀⣴⣾⣿⡿⡟⡋⠐⡇⠀⢸⣿⣿⠃⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢡⠘⢰⣿⡿⡆⠀⣇⠀⣀⣠⣤⣶⣿⢷⢟⠻⠀⠈⠀⠀⠀⡇⠀⣼⣿⣿⠂⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⠔⢀⡴⢯⣾⠟⡏⢀⣠⣿⣿⣿⣟⢟⡋⠅⠘⠉⠀⠀⠀⠀⢀⠀⠁⢠⣿⣟⠃⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠞⣻⣷⡿⢙⣩⣶⡿⠿⠛⠉⠑⢡⡁⠀⠀⠀⠀⠀⠀⢀⠔⠁⠀⣰⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣡⣾⣥⣾⢫⡦⠾⠛⠙⠉⠀⠀⢀⣀⠀⠈⠙⠓⠦⠤⠤⠀⠘⠁⢀⡤⣾⡿⠏⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠔⣴⣾⣿⣿⢟⢝⠢⠃⢀⣤⢴⣾⣮⣷⣶⢿⣶⡤⣐⡀⠀⣠⣤⢶⣪⣿⣿⡿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⡀⣦⣾⡿⡛⠵⠺⢈⡠⠶⠿⠥⠥⡭⠉⠉⢱⡛⠻⠿⣿⣿⣿⣿⣿⠿⠿⠿⠟⠭⠛⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢀⢴⠕⣋⠝⠕⠐⠀⠔⠉⠀⠀⠀⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠁⠉⠁⠁⠁⠁⠈⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢀⣠⠁⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀


    ${NC}"
}

# ------------------------------------------------------------------------------
# Function: detect_system
# Description:
#   Identifies the operating system (Arch/Debian/Fedora/OpenSUSE) and checks for Flatpak.
# Sets globals: IS_FLATPAK, IS_ARCH, IS_DEBIAN, IS_FEDORA, IS_SUSE
# ------------------------------------------------------------------------------
detect_system() {
    # Check for Flatpak
    if command -v flatpak &> /dev/null; then
        log_warn "Flatpak detected, checking for Brave Browser..."
        if flatpak list | grep -q "com.brave.Browser"; then
            IS_FLATPAK=true
            log_info "✓ Confirmed Brave Browser is installed via Flatpak"
        fi
    fi

    # Check OS Release
    if [ -f "/etc/os-release" ]; then
        source /etc/os-release
        case "$ID" in
            steamos|arch|manjaro)
                IS_ARCH=true
                log_info "Detected Arch-based system"
                ;;
            debian|ubuntu|linuxmint|pop|neon)
                IS_DEBIAN=true
                log_info "Detected Debian-based system"
                ;;
            fedora|rhel|centos|almalinux|rocky)
                IS_FEDORA=true
                log_info "Detected Fedora/RHEL-based system"
                ;;
            opensuse*|suse)
                IS_SUSE=true
                log_info "Detected openSUSE-based system"
                ;;
            *)
                # Check ID_LIKE as fallback
                if [[ "$ID_LIKE" == *"arch"* ]]; then
                    IS_ARCH=true
                    log_info "Detected Arch-based system (via ID_LIKE)"
                elif [[ "$ID_LIKE" == *"debian"* ]]; then
                    IS_DEBIAN=true
                    log_info "Detected Debian-based system (via ID_LIKE)"
                elif [[ "$ID_LIKE" == *"fedora"* || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"centos"* ]]; then
                    IS_FEDORA=true
                    log_info "Detected Fedora/RHEL-based system (via ID_LIKE)"
                elif [[ "$ID_LIKE" == *"suse"* ]]; then
                    IS_SUSE=true
                    log_info "Detected openSUSE-based system (via ID_LIKE)"
                else
                    log_warn "Unrecognized OS type: $ID"
                    log_warn "Continuing with generic Linux support"
                fi
                ;;
        esac
    fi
}

# ------------------------------------------------------------------------------
# Function: find_brave_executable
# Description:
#   Locates the Brave Browser executable or Flatpak command.
#   Exits if no installation is found.
# Sets global: BRAVE_EXEC
# ------------------------------------------------------------------------------
find_brave_executable() {
    # If already found via flatpak, we are good
    if [ "$IS_FLATPAK" = true ]; then
        BRAVE_EXEC="flatpak run com.brave.Browser"
        return
    fi
    
    # Check native installations
    if command -v brave-browser &> /dev/null; then
        BRAVE_EXEC="brave-browser"
        log_info "Found Brave Browser installed natively"
    elif command -v brave &> /dev/null; then
        BRAVE_EXEC="brave"
        log_info "Found Brave Browser installed natively (brave command)"
    else
        log_warn "No native Brave installation found, rechecking Flatpak..."
        # Fallback checks for Flatpak
        if [ -d "$HOME/.var/app/com.brave.Browser" ]; then
            IS_FLATPAK=true
            BRAVE_EXEC="flatpak run com.brave.Browser"
            log_info "Found Brave Browser Flatpak directory"
        else
            # Check common flatpak export locations
            local flatpak_dirs=(
                "$HOME/.local/share/flatpak/exports/share/applications"
                "/var/lib/flatpak/exports/share/applications"
            )
            for location in "${flatpak_dirs[@]}"; do
                if [ -f "$location/com.brave.Browser.desktop" ]; then
                    IS_FLATPAK=true
                    BRAVE_EXEC="flatpak run com.brave.Browser"
                    log_info "Found Brave Browser Flatpak desktop file"
                    break
                fi
            done
        fi
    fi

    if [ -z "$BRAVE_EXEC" ]; then
        log_error "Error: Could not find Brave Browser installation."
        log_warn "If you're sure Brave is installed, please run it once to create necessary directories,"
        log_warn "or specify the installation path manually by editing this script."
        exit 1
    fi
    
    log_info "Using Brave executable: $BRAVE_EXEC"
}

# ------------------------------------------------------------------------------
# Function: prompt_for_ai_choice
# Description:
#   Asks the user whether to disable Brave AI/Leo features.
#   Supports non-interactive mode via DISABLE_BRAVE_AI env var.
# Sets global: DISABLE_BRAVE_AI
# ------------------------------------------------------------------------------
prompt_for_ai_choice() {
    # Allow non-interactive override through DISABLE_BRAVE_AI env var
    if [ -n "$DISABLE_BRAVE_AI" ]; then
        case "${DISABLE_BRAVE_AI,,}" in
            y|yes|true|1) DISABLE_BRAVE_AI=true ;;
            n|no|false|0) DISABLE_BRAVE_AI=false ;;
            *)
                log_warn "Unrecognized DISABLE_BRAVE_AI value. Defaulting to disabling Brave AI features."
                DISABLE_BRAVE_AI=true
                ;;
        esac
        return
    fi

    if [ -t 0 ]; then
        read -r -p "$(echo -e "${BLUE}Disable Brave AI/Leo features (recommended)? [Y/n]: ${NC}")" RESPONSE
        case "${RESPONSE,,}" in
            n|no) DISABLE_BRAVE_AI=false ;;
            *)    DISABLE_BRAVE_AI=true ;;
        esac
    else
        # Non-interactive shell: default to disabling AI for privacy
        DISABLE_BRAVE_AI=true
    fi
}

# ==============================================================================
# Configuration Management Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Function: find_profile_directory
# Description:
#   Locates the Brave user profile directory for preference modification.
# Sets globals: BRAVE_DIR, PROFILE_DIR
# ------------------------------------------------------------------------------
find_profile_directory() {
    # Determine base directory
    if [ "$IS_FLATPAK" = true ]; then
        if [ -d "$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser" ]; then
            BRAVE_DIR="$HOME/.var/app/com.brave.Browser/config/BraveSoftware/Brave-Browser"
        else
            BRAVE_DIR="$HOME/.var/app/com.brave.Browser/.config/BraveSoftware/Brave-Browser"
        fi
    else
        BRAVE_DIR="$HOME/.config/BraveSoftware/Brave-Browser"
    fi

    # Check if profile directory exists
    if [ -d "$BRAVE_DIR" ]; then
        if [ -d "$BRAVE_DIR/$DEFAULT_PROFILE" ]; then
            PROFILE_DIR="$BRAVE_DIR/$DEFAULT_PROFILE"
            log_info "Found Brave profile at: $PROFILE_DIR"
        else
            PROFILE_DIR=$(find "$BRAVE_DIR" -type d -name "Profile*" 2>/dev/null | head -n 1)
            if [ -n "$PROFILE_DIR" ]; then
                log_info "Found Brave profile at: $PROFILE_DIR"
            else
                log_warn "No profile directory found in $BRAVE_DIR"
                log_warn "Will continue with other configurations"
            fi
        fi
    else
        log_warn "Brave configuration directory not found at: $BRAVE_DIR"
        log_warn "Looking for alternative locations..."
        
        local alt_locations=(
            "$HOME/.config/brave"
            "$HOME/.var/app/com.brave.Browser/config/brave"
            "$HOME/.var/app/com.brave.Browser/.config/brave"
        )
        
        for dir in "${alt_locations[@]}"; do
            if [ -d "$dir" ]; then
                BRAVE_DIR="$dir"
                if [ -d "$dir/$DEFAULT_PROFILE" ]; then
                    PROFILE_DIR="$dir/$DEFAULT_PROFILE"
                else
                    PROFILE_DIR=$(find "$dir" -type d -name "Profile*" 2>/dev/null | head -n 1)
                fi
                
                if [ -n "$PROFILE_DIR" ]; then
                    log_info "Found Brave directory at: $BRAVE_DIR"
                    log_info "Found Brave profile at: $PROFILE_DIR"
                    break
                fi
            fi
        done
        
        if [ -z "$PROFILE_DIR" ]; then
            log_warn "No Brave profile found. Have you run Brave at least once?"
            log_warn "Will continue with other configurations"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: create_backups
# Description:
#   Creates a timestamped backup of Brave configuration files.
#   Backs up: Preferences, Local State
# ------------------------------------------------------------------------------
create_backups() {
    [ -z "$PROFILE_DIR" ] && return

    BACKUP_DIR="$HOME/brave-backup-$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    log_section "Creating backup in $BACKUP_DIR"

    if [ -f "$PROFILE_DIR/Preferences" ]; then
        cp "$PROFILE_DIR/Preferences" "$BACKUP_DIR/Preferences.bak"
        log_info "✓ Preferences backup created"
    fi

    if [ -f "$BRAVE_DIR/Local State" ]; then
        cp "$BRAVE_DIR/Local State" "$BACKUP_DIR/Local_State.bak"
        log_info "✓ Local State backup created"
    fi
}

# ------------------------------------------------------------------------------
# Function: ensure_jq
# Description:
#   Checks if 'jq' is installed. Tries to install it if running as root
#   using the appropriate package manager (apt, pacman, dnf, zypper).
# Sets global: JQ_AVAILABLE
# ------------------------------------------------------------------------------
ensure_jq() {
    if command -v jq &> /dev/null; then
        JQ_AVAILABLE=true
        return
    fi
    
    log_warn "jq not found. Attempting to install..."
    
    if [ "$IS_ROOT" = true ]; then
        if [ "$IS_DEBIAN" = true ]; then
            apt-get update && apt-get install -y jq && JQ_AVAILABLE=true
        elif [ "$IS_ARCH" = true ]; then
            pacman -Sy --noconfirm jq && JQ_AVAILABLE=true
        elif [ "$IS_FEDORA" = true ]; then
            dnf install -y jq && JQ_AVAILABLE=true
        elif [ "$IS_SUSE" = true ]; then
            zypper install -y jq && JQ_AVAILABLE=true
        else
            log_warn "Could not determine package manager to install jq automatically."
            log_warn "Please install 'jq' manually."
        fi
    else
        log_warn "Not running as root, can't install jq automatically."
        log_warn "Please install jq manually for better preference handling:"
        if [ "$IS_DEBIAN" = true ]; then
            log_warn "  sudo apt-get update && sudo apt-get install -y jq"
        elif [ "$IS_ARCH" = true ]; then
            log_warn "  sudo pacman -Sy --noconfirm jq"
        elif [ "$IS_FEDORA" = true ]; then
            log_warn "  sudo dnf install -y jq"
        elif [ "$IS_SUSE" = true ]; then
            log_warn "  sudo zypper install -y jq"
        else
            log_warn "  Install 'jq' using your system's package manager."
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: modify_preference
# Description:
#   Uses jq to safely modify a JSON key in the preferences file.
# Arguments:
#   $1 - JSON Key path (e.g., '.brave.rewards.enabled')
#   $2 - Value (e.g., 'false')
#   $3 - File path
# ------------------------------------------------------------------------------
modify_preference() {
    local key=$1
    local value=$2
    local file=$3
    
    [ -f "$file" ] || { log_warn "Warning: File not found: $file"; return; }
    [ "$JQ_AVAILABLE" = true ] || { log_warn "Warning: 'jq' is not installed. Skipping preference modification."; return; }

    local temp_file=$(mktemp)
    jq "$key = $value" "$file" > "$temp_file"
    
    if [ $? -eq 0 ]; then
        mv "$temp_file" "$file"
        log_info "✓ Set $key to $value"
    else
        log_error "Error: Failed to modify preference $key"
        rm "$temp_file"
    fi
}

# ------------------------------------------------------------------------------
# Function: remove_flag_from_local_state
# Description:
#   Removes a specific experiment flag from the Local State file.
# Arguments:
#   $1 - Flag to remove
#   $2 - File path
# ------------------------------------------------------------------------------
remove_flag_from_local_state() {
    local flag=$1
    local file=$2

    [ -f "$file" ] || { log_warn "Warning: File not found: $file"; return; }
    [ "$JQ_AVAILABLE" = true ] || { log_warn "Warning: 'jq' is not installed. Skipping flag removal for $flag."; return; }

    local temp_file=$(mktemp)
    jq --arg flag "$flag" '
        .browser.enabled_labs_experiments =
            (.browser.enabled_labs_experiments // [] | map(select(. != $flag)))
    ' "$file" > "$temp_file"

    if [ $? -eq 0 ]; then
        mv "$temp_file" "$file"
        log_info "✓ Removed lab flag: $flag"
    else
        log_error "Error: Failed to remove lab flag $flag"
        rm "$temp_file"
    fi
}

# ==============================================================================
# Execution Functions
# ==============================================================================

# ------------------------------------------------------------------------------
# Function: setup_launch_script
# Description:
#   Creates a custom wrapper script to launch Brave with privacy flags.
#   Saved to ~/.local/bin/brave-private
# ------------------------------------------------------------------------------
setup_launch_script() {
    local features=("${BASE_DISABLED_FEATURES[@]}")
    if [ "$DISABLE_BRAVE_AI" = true ]; then
        features+=("${AI_DISABLED_FEATURES[@]}")
    fi
    
    local disable_features_arg=$(IFS=,; echo "${features[*]}")
    
    log_section "Creating custom Brave launch script"
    local launch_script="$HOME/.local/bin/brave-private"
    mkdir -p "$HOME/.local/bin"

    local cmd_start
    if [ "$IS_FLATPAK" = true ]; then
        cmd_start="flatpak run com.brave.Browser"
    else
        cmd_start="$BRAVE_EXEC"
    fi

cat > "$launch_script" << EOL
#!/bin/bash

$cmd_start \\
    --disable-brave-sync \\
    --disable-features=${disable_features_arg} \\
    --disable-background-networking \\
    --disable-component-extensions-with-background-pages \\
    --disable-domain-reliability \\
    --disable-sync-preferences \\
    --disable-site-isolation-trials \\
    --disable-prediction-service \\
    --disable-remote-fonts \\
    --disable-extensions-http-throttling \\
    --disable-breakpad \\
    --disable-speech-api \\
    --disable-translate \\
    --disable-sync \\
    --disable-first-run-ui \\
    --disable-client-side-phishing-detection \\
    --disable-component-updater \\
    --disable-suggestions-service \\
    --disable-webgl \\
    --no-pings \\
    --no-report-upload \\
    --no-service-autorun \\
    --no-first-run \\
    --aggressive-cache-discard \\
    --metrics-recording-only \\
    --clear-token-service \\
    --reset-variation-state \\
    --block-new-web-contents \\
    --start-maximized \\
    --incognito \\
    "\$@"
EOL

    chmod +x "$launch_script"
    log_info "✓ Created private Brave launcher at: $launch_script"
    log_warn "Run Brave with improved privacy using: $launch_script"
}

# ------------------------------------------------------------------------------
# Function: create_desktop_launcher
# Description:
#   Creates a .desktop entry for the private launcher.
#   Saved to ~/.local/share/applications/brave-private.desktop
# ------------------------------------------------------------------------------
create_desktop_launcher() {
    local desktop_entry="$HOME/.local/share/applications/brave-private.desktop"
    mkdir -p "$HOME/.local/share/applications"

    local icon_path="brave-browser"
    [ "$IS_FLATPAK" = true ] && icon_path="com.brave.Browser"

    cat > "$desktop_entry" << EOL
[Desktop Entry]
Version=1.0
Name=Brave (Private Mode)
GenericName=Web Browser - Privacy Mode
Comment=Access the Internet with enhanced privacy settings
Exec=$HOME/.local/bin/brave-private %U
Icon=$icon_path
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupNotify=true
EOL

    log_info "✓ Created desktop launcher for private Brave"
}

# ------------------------------------------------------------------------------
# Function: apply_preferences
# Description:
#   Modifies Brave's 'Preferences' and 'Local State' files to disable
#   rewards, wallet, and telemetry if Brave is not running.
# ------------------------------------------------------------------------------
apply_preferences() {
    [ -n "$PROFILE_DIR" ] && [ "$JQ_AVAILABLE" = true ] || return
    
    log_section "Modifying Brave preferences"

    if pgrep -f "brave" > /dev/null || pgrep -f "com.brave.Browser" > /dev/null; then
        log_warn "Warning: Brave Browser is currently running."
        log_warn "Close Brave Browser and run this script again for full effect."
        return
    else
        local pref_file="$PROFILE_DIR/Preferences"
        if [ -f "$pref_file" ]; then
            # Rewards
            modify_preference '.brave.rewards.enabled' 'false' "$pref_file"
            modify_preference '.brave.rewards.hide_button' 'true' "$pref_file"
            # Ads
            modify_preference '.brave.brave_ads.enabled' 'false' "$pref_file"
            modify_preference '.brave.brave_ads.opted_in' 'false' "$pref_file"
            # Wallet
            modify_preference '.brave.wallet.rpc_allowed_origins' '[]' "$pref_file"
            modify_preference '.brave.wallet.keyring_lock_timeout_mins' '0' "$pref_file"
            # Telemetry
            modify_preference '.brave.p3a_enabled' 'false' "$pref_file"
            modify_preference '.brave.stats.usage_ping_enabled' 'false' "$pref_file"
            # Others
            modify_preference '.brave.today.opted_in' 'false' "$pref_file"
            modify_preference '.brave.ipfs.enabled' 'false' "$pref_file"

            if [ "$DISABLE_BRAVE_AI" = true ]; then
                modify_preference '.brave.leo.enabled' 'false' "$pref_file"
                modify_preference '.brave.leo.onboarding_seen' 'true' "$pref_file"
                modify_preference '.brave.ai_chat.enabled' 'false' "$pref_file"
                modify_preference '.brave.ai.autocomplete_enabled' 'false' "$pref_file"
            fi
            log_info "✓ Updated Brave preferences"
        else
            log_warn "Warning: Preferences file not found at $pref_file"
        fi
        
        # Local State
        local local_state_file="$BRAVE_DIR/Local State"
        if [ -f "$local_state_file" ]; then
            local flags_to_disable=(
                "brave-news" "brave-speedreader" "brave-wallet"
                "brave-ads-custom-push-notifications" "brave-vpn" "ipfs"
            )
            if [ "$DISABLE_BRAVE_AI" = true ]; then
                flags_to_disable+=("brave-leo" "brave-leo-inline" "brave-leo-lite" "brave-ai-chat" "brave-ai-prompts" "brave-ai-autocomplete")
            fi
            
            for flag in "${flags_to_disable[@]}"; do
                remove_flag_from_local_state "$flag" "$local_state_file"
            done
            log_info "✓ Disabled Brave flags in Local State file"
        else
            log_warn "Warning: Local State file not found at $local_state_file"
        fi
    fi
}

# ------------------------------------------------------------------------------
# Function: block_telemetry
# Description:
#   Adds blocks to /etc/hosts for known Brave telemetry domains.
#   Requires root privileges.
# ------------------------------------------------------------------------------
block_telemetry() {
    log_section "Setting up network-level blocks"
    
    if [ "$IS_ROOT" = true ]; then
        cp /etc/hosts "$BACKUP_DIR/hosts.bak" 2>/dev/null
        log_info "✓ Created hosts file backup"
        
        local modified=false
        for entry in "${HOSTS_ENTRIES[@]}"; do
            if ! grep -q "$entry" /etc/hosts; then
                echo "$entry" >> /etc/hosts
                modified=true
            fi
        done
        
        if [ "$modified" = true ]; then
            log_info "✓ Added Brave telemetry domains to /etc/hosts"
        else
            log_info "✓ All Brave telemetry domains already blocked in /etc/hosts"
        fi
    else
        log_warn "Not running as root, cannot modify /etc/hosts file."
        log_warn "To block Brave telemetry domains, add these lines to /etc/hosts:"
        for entry in "${HOSTS_ENTRIES[@]}"; do
            echo "   $entry"
        done
        log_warn "Run: sudo nano /etc/hosts"
    fi
}

# ------------------------------------------------------------------------------
# Function: create_dns_block_script
# Description:
#   Generates a standalone script for firewall-based blocking (iptables/nftables)
#   as an alternative to hosts file blocking.
# ------------------------------------------------------------------------------
create_dns_block_script() {
    local script="$HOME/.local/bin/brave-dns-block.sh"
    
    # We use a literal heredoc since strictly no variable interpolation is needed from main script
    
    cat > "$script" << 'EOL'
#!/bin/bash
# Block Brave browser telemetry using iptables/nftables
# Run with sudo permissions

BRAVE_DOMAINS=(
    "variations.brave.com" "go-updater.brave.com" "componentupdater.brave.com"
    "crlsets.brave.com" "laptop-updates.brave.com" "brave-core-ext.s3.brave.com"
    "grant.rewards.brave.com" "stats.brave.com" "p3a.brave.com" "analytics.brave.com"
    "rewards.brave.com" "pcdn.brave.com"
)

[ "$EUID" -ne 0 ] && { echo "Please run as root"; exit 1; }

if command -v nft &> /dev/null; then
    echo "Using nftables..."
    nft list tables | grep -q "brave_block" || {
        nft add table inet brave_block
        nft add chain inet brave_block output { type filter hook output priority 0 \; }
    }
    for domain in "${BRAVE_DOMAINS[@]}"; do
        ips=$(dig +short "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
        for ip in $ips; do
            nft list table inet brave_block | grep -q "$ip" || {
                nft add rule inet brave_block output ip daddr $ip drop
                echo "Blocked $domain ($ip)"
            }
        done
    done
elif command -v iptables &> /dev/null; then
    echo "Using iptables..."
    for domain in "${BRAVE_DOMAINS[@]}"; do
        ips=$(dig +short "$domain" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
        for ip in $ips; do
            iptables -C OUTPUT -d "$ip" -j REJECT 2>/dev/null || {
                iptables -A OUTPUT -d "$ip" -j REJECT
                echo "Blocked $domain ($ip)"
            }
        done
    done
else
    echo "No firewall tool found."
    exit 1
fi
echo "Blocking complete"
EOL

    chmod +x "$script"
    log_info "✓ Created DNS blocking script at: $script"
    log_warn "Run with: sudo $script"
}

# ------------------------------------------------------------------------------
# Function: apply_flatpak_overrides
# Description:
#   Applies Flatpak permission overrides to restrict Brave's access if installed
#   via Flatpak.
# ------------------------------------------------------------------------------
apply_flatpak_overrides() {
    [ "$IS_FLATPAK" = true ] || return
    
    log_section "Setting up Flatpak-specific overrides for Brave"
    
    if flatpak override --user com.brave.Browser --no-autostart &>/dev/null; then
        log_info "✓ Created Flatpak override to disable autostart"
        flatpak override --user com.brave.Browser --nosocket=session-bus &>/dev/null
        flatpak override --user com.brave.Browser --nofilesystem=xdg-download/brave-telemetry &>/dev/null
        log_info "✓ Applied additional Flatpak privacy overrides"
    else
        log_warn "Unable to create Flatpak overrides. You may need to run:"
        log_warn "flatpak override --user com.brave.Browser --no-autostart"
    fi
}

# ------------------------------------------------------------------------------
# Function: print_summary
# Description:
#   Displays a final summary of actions taken and recommended next steps.
# ------------------------------------------------------------------------------
print_summary() {
    log_section "=== Setup Complete ==="
    log_info "Brave Browser has been configured for enhanced privacy:"
    echo "1. Created private launcher: $HOME/.local/bin/brave-private"
    echo "2. Added desktop shortcut: Brave (Private Mode)"
    echo "3. Created network blocking tools"
    
    [ -n "$PROFILE_DIR" ] && [ "$JQ_AVAILABLE" = true ] && echo "4. Modified browser preferences"
    [ "$IS_FLATPAK" = true ] && echo "5. Applied Flatpak-specific overrides"
    
    log_section "=== Recommended Additional Steps ==="
    echo -e "1. Manually verify settings at: ${YELLOW}brave://settings/privacy${NC}"
    echo -e "2. Verify flag settings at: ${YELLOW}brave://flags/${NC}"
    echo -e "3. Consider using a privacy-focused DNS like NextDNS or Pi-hole"
    echo -e "4. Install: uBlock Origin, Privacy Badger, ClearURLs"
    
    if [ "$IS_DEBIAN" = true ] && [ "$IS_ROOT" = false ]; then
        log_warn "\nFor Debian-based systems:"
        echo -e "Run this script with sudo for full functionality: ${YELLOW}sudo $0${NC}"
    elif [ "$IS_FEDORA" = true ] && [ "$IS_ROOT" = false ]; then
        log_warn "\nFor Fedora-based systems:"
        echo -e "Run this script with sudo for full functionality: ${YELLOW}sudo $0${NC}"
    elif [ "$IS_SUSE" = true ] && [ "$IS_ROOT" = false ]; then
        log_warn "\nFor openSUSE-based systems:"
        echo -e "Run this script with sudo for full functionality: ${YELLOW}sudo $0${NC}"
    fi
    
    log_info "\nLaunch privacy-focused Brave with: $HOME/.local/bin/brave-private"
}

# ==============================================================================
# Main Execution Flow
# ==============================================================================

# ------------------------------------------------------------------------------
# Function: main
# Description:
#   Orchestrates the script execution by calling other functions in order.
# Arguments:
#   $@ - Command line arguments (passed to any relevant sub-commands)
# ------------------------------------------------------------------------------
main() {
    clear
    banner
    log_section "=== Brave Browser Privacy & Debloating Script ==="
    
    check_root
    detect_system
    prompt_for_ai_choice
    find_brave_executable
    find_profile_directory
    
    create_backups
    ensure_jq
    
    setup_launch_script
    create_desktop_launcher
    
    apply_preferences
    block_telemetry
    create_dns_block_script
    apply_flatpak_overrides
    
    print_summary
}

# Execute main function with all arguments
main "$@"
