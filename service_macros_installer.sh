#!/bin/bash
#
# Klipper-Service-Macros Installer / Updater / Uninstaller
# - Fully updated for latest Moonraker update_manager schema
# - Cleans old/invalid update_manager entries
# - Cleans moonraker.asvc service list for service_macros
# - Symlinks repo Configuration/ to printer_data/config/ServiceMacros
# - Manages ServiceSettings.cfg with safe merging + include normalization
# - Interactive reboot prompt (Y/N)
#

set -euo pipefail

USER_HOME="$(getent passwd "$(whoami)" | cut -d: -f6)"

REPO_URL="https://github.com/Herculez3D/Klipper-Service-Macros.git"
REPO_DIR="$USER_HOME/Klipper-Service-Macros"

CONFIG_DIR="$USER_HOME/printer_data/config"
MACRO_DIR="$CONFIG_DIR/ServiceMacros"
USER_SETTINGS="$CONFIG_DIR/ServiceSettings.cfg"
REPO_SETTINGS="$REPO_DIR/Configuration/ServiceSettings.cfg"

MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
MOONRAKER_ASVC="$USER_HOME/printer_data/moonraker.asvc"
UPDATE_NAME="service_macros"

###############################################################################
# LOGGING
###############################################################################
info() { echo -e "\e[32m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

###############################################################################
# INCLUDE NORMALIZATION
###############################################################################
normalize_includes() {
    if [[ ! -f "$USER_SETTINGS" ]]; then return; fi

    # Remove any existing include lines that reference ServiceMacros to avoid duplicates / bad paths
    sed -i '/\[include .*ServiceMacros\/ServiceMacros.cfg]/d' "$USER_SETTINGS"
    sed -i '/\[include .*\.\/ServiceMacros\/ServiceMacros.cfg]/d' "$USER_SETTINGS"

    # Add a single clean include at the top
    sed -i '1i [include ServiceMacros/ServiceMacros.cfg]' "$USER_SETTINGS"

    info "Include normalized in ServiceSettings.cfg"
}

###############################################################################
# MERGE SETTINGS
###############################################################################
merge_settings() {
    if [[ ! -f "$REPO_SETTINGS" ]]; then
        error "Template settings file not found at: $REPO_SETTINGS"
    fi

    if [[ ! -f "$USER_SETTINGS" ]]; then
        info "No existing user settings. Installing defaults..."
        cp "$REPO_SETTINGS" "$USER_SETTINGS"
        normalize_includes
        return
    fi

    info "Merging template defaults into existing user settings..."

    TEMP="/tmp/ServiceSettings_merged.cfg"

    awk '
        FNR==NR {
            if ($0 ~ /^\[/) section=$0
            if ($0 ~ /=/) existing[section,$1]=$0
            next
        }
        {
            if ($0 ~ /^\[/) section=$0
            if ($0 ~ /=/) {
                key=$1
                if ((section,key) in existing)
                    print existing[section,key]
                else
                    print $0
            } else print $0
        }
    ' "$USER_SETTINGS" "$REPO_SETTINGS" > "$TEMP"

    mv "$TEMP" "$USER_SETTINGS"
    normalize_includes
}

###############################################################################
# SYMLINK CREATION
###############################################################################
create_symlink() {
    info "Ensuring ServiceMacros symlink exists..."

    if [[ -e "$MACRO_DIR" || -L "$MACRO_DIR" ]]; then
        warn "Existing ServiceMacros entry found at $MACRO_DIR. Removing it..."
        rm -rf "$MACRO_DIR"
    fi

    mkdir -p "$REPO_DIR/Configuration"

    ln -s "$REPO_DIR/Configuration" "$MACRO_DIR"

    info "Symlink created: $MACRO_DIR -> $REPO_DIR/Configuration"
}

###############################################################################
# CLEAN OLD MOONRAKER ENTRIES
###############################################################################
clean_old_update_manager_entries() {
    if [[ ! -f "$MOONRAKER_CONF" ]]; then
        return
    fi

    # Remove ANY old [update_manager service_macros] block (with legacy keys)
    sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF" || true

    info "Old update_manager entries for $UPDATE_NAME removed (if any)."
}

clean_moonraker_asvc() {
    if [[ ! -f "$MOONRAKER_ASVC" ]]; then
        return
    fi

    # Remove any line that is exactly 'service_macros' (with or without surrounding whitespace)
    sed -i '/^[[:space:]]*service_macros[[:space:]]*$/d' "$MOONRAKER_ASVC" || true

    info "Removed service_macros from moonraker.asvc (if it existed)."
}

###############################################################################
# UPDATE MANAGER CONFIG
###############################################################################
add_update_manager() {
    info "Configuring Moonraker update_manager entry..."

    mkdir -p "$(dirname "$MOONRAKER_CONF")"

    # Remove any old blocks
    sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF" || true

    # Write Moonraker-compatible block
    cat <<EOF >> "$MOONRAKER_CONF"

[update_manager $UPDATE_NAME]
type: git_repo
path: $REPO_DIR
origin: $REPO_URL
install_script: service_macros_installer.sh
is_system_service: False
EOF

    info "Moonraker update_manager entry added for $UPDATE_NAME."
}

###############################################################################
# REBOOT PROMPT
###############################################################################
prompt_reboot() {
    echo -ne "\nWould you like to reboot now? (Y/N): "
    read -r ans
    case "$ans" in
        [Yy]* )
            info "Rebooting..."
            sudo reboot
            ;;
        * )
            info "Reboot skipped."
            ;;
    esac
}

###############################################################################
# INSTALL
###############################################################################
install_macros() {
    info "=== INSTALL: Klipper-Service-Macros ==="

    mkdir -p "$CONFIG_DIR"

    if [[ -d "$REPO_DIR/.git" ]]; then
        info "Existing repository detected. Pulling latest changes..."
        git -C "$REPO_DIR" pull
    else
        info "Cloning repository into: $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    create_symlink
    merge_settings
    clean_moonraker_asvc
    add_update_manager

    info "Restarting Moonraker and Klipper..."
    sudo systemctl restart moonraker || warn "Moonraker restart failed or is not present."
    sudo systemctl restart klipper || warn "Klipper restart failed or is not present."

    info "=== INSTALL COMPLETE ==="
    prompt_reboot
}

###############################################################################
# UPDATE
###############################################################################
update_macros() {
    info "=== UPDATE: Klipper-Service-Macros ==="

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        warn "Repository not found. Running fresh install..."
        install_macros
        return
    fi

    git -C "$REPO_DIR" pull

    create_symlink
    merge_settings
    clean_moonraker_asvc
    add_update_manager

    sudo systemctl restart moonraker || warn "Moonraker restart failed or is not present."
    sudo systemctl restart klipper || warn "Klipper restart failed or is not present."

    info "=== UPDATE COMPLETE ==="
    prompt_reboot
}

###############################################################################
# UNINSTALL
###############################################################################
uninstall_macros() {
    info "=== UNINSTALL: Klipper-Service-Macros ==="

    if [[ -e "$MACRO_DIR" || -L "$MACRO_DIR" ]]; then
        rm -rf "$MACRO_DIR"
        info "Removed ServiceMacros from config directory."
    fi

    if [[ -d "$REPO_DIR" ]]; then
        rm -rf "$REPO_DIR"
        info "Removed repo at $REPO_DIR."
    fi

    if [[ -f "$MOONRAKER_CONF" ]]; then
        sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF" || true
        info "Removed update_manager entry from moonraker.conf."
    fi

    clean_moonraker_asvc

    sudo systemctl restart moonraker || warn "Moonraker restart failed or is not present."
    sudo systemctl restart klipper || warn "Klipper restart failed or is not present."

    info "=== UNINSTALL COMPLETE ==="
    prompt_reboot
}

###############################################################################
# MAIN
###############################################################################
case "${1:-}" in
    install)   install_macros ;;
    update)    update_macros ;;
    uninstall) uninstall_macros ;;
    *)
        echo "Usage: $0 {install|update|uninstall}"
        ;;
esac
