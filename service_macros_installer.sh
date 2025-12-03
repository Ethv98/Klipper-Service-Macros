#!/bin/bash
#
# Klipper-Service-Macros Installer / Updater / Uninstaller
# VERSION: V2.0.0-Beta
# - Mirrors repo V2 layout into printer_data/config
# - Merges ServiceSettings.cfg (user edits preserved where keys exist)
# - Makes macro .cfg files read-only, ServiceSettings.cfg editable
# - Adds legacy-style Moonraker update_manager entry for this branch
#

set -euo pipefail

# Detect actual user home (pi, voron, mainsail, etc.)
USER_HOME="$(getent passwd "$(whoami)" | cut -d: -f6)"

VERSION="V2.0.0-Beta"
REPO_URL="https://github.com/Herculez3D/Klipper-Service-Macros.git"
REPO_DIR="$USER_HOME/Klipper-Service-Macros"

CONFIG_DIR="$USER_HOME/printer_data/config"
MACRO_DIR="$CONFIG_DIR/ServiceMacros"
USER_SETTINGS="$CONFIG_DIR/ServiceSettings.cfg"
REPO_SETTINGS="$REPO_DIR/Configuration/ServiceSettings.cfg"

MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
MOONRAKER_ASVC="$USER_HOME/printer_data/moonraker.asvc"
UPDATE_NAME="service_macros"

info(){ echo -e "\e[32m[INFO]\e[0m $1"; }
warn(){ echo -e "\e[33m[WARN]\e[0m $1"; }
error(){ echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

###############################################################################
# MERGE USER SETTINGS WITH TEMPLATE (PRESERVE USER VALUES WHERE KEYS EXIST)
###############################################################################
merge_settings() {
    if [[ ! -f "$REPO_SETTINGS" ]]; then
        error "Template ServiceSettings.cfg not found at: $REPO_SETTINGS"
    fi

    # First-time install: copy template directly
    if [[ ! -f "$USER_SETTINGS" ]]; then
        info "No existing ServiceSettings.cfg found. Installing template..."
        cp "$REPO_SETTINGS" "$USER_SETTINGS"
        chmod 644 "$USER_SETTINGS"
        return
    fi

    info "Merging existing ServiceSettings.cfg with template..."

    TEMP="/tmp/ServiceSettings_merged.cfg"

    # Merge logic:
    #  - Use structure from template
    #  - For keys that already exist in user file, keep user lines
    #  - For new keys, use template lines
    #  - Non-key lines (comments, includes, etc.) follow template layout
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
    chmod 644 "$USER_SETTINGS"
    info "ServiceSettings.cfg merged and left editable."
}

###############################################################################
# MIRROR REPO STRUCTURE INTO MAINSAIL
###############################################################################
mirror_structure() {
    info "Mirroring V2 Configuration layout into printer_data/config..."

    # Clear and recreate ServiceMacros folder
    rm -rf "$MACRO_DIR" || true
    mkdir -p "$MACRO_DIR"

    # Copy Configuration/ServiceMacros/* → printer_data/config/ServiceMacros/
    if [[ -d "$REPO_DIR/Configuration/ServiceMacros" ]]; then
        cp -r "$REPO_DIR/Configuration/ServiceMacros/"* "$MACRO_DIR"/
    else
        error "Expected folder not found: $REPO_DIR/Configuration/ServiceMacros"
    fi

    # Make all .cfg files under ServiceMacros read-only
    find "$MACRO_DIR" -type f -name "*.cfg" -exec chmod 444 {} \;

    info "ServiceMacros/*.cfg set to read-only."
}

###############################################################################
# CLEAN OLD MOONRAKER CONFIG ENTRIES
###############################################################################
clean_old_configs() {
    if [[ -f "$MOONRAKER_CONF" ]]; then
        sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF" || true
        info "Removed old [update_manager $UPDATE_NAME] block from moonraker.conf (if present)."
    fi
    if [[ -f "$MOONRAKER_ASVC" ]]; then
        sed -i '/^[[:space:]]*service_macros[[:space:]]*$/d' "$MOONRAKER_ASVC" || true
        info "Removed service_macros from moonraker.asvc (if present)."
    fi
}

###############################################################################
# ADD MOONRAKER UPDATE MANAGER ENTRY (LEGACY SCHEMA WITH origin + primary_branch)
###############################################################################
add_update_manager() {
    info "Configuring Moonraker update_manager entry for V2..."

    mkdir -p "$(dirname "$MOONRAKER_CONF")"
    clean_old_configs

    cat <<EOF >> "$MOONRAKER_CONF"

[update_manager $UPDATE_NAME]
type: git_repo
path: $REPO_DIR
origin: $REPO_URL
primary_branch: $VERSION
install_script: service_macros_installer.sh
is_system_service: False
EOF

    info "Added [update_manager $UPDATE_NAME] entry targeting branch: $VERSION"
}

###############################################################################
# REBOOT PROMPT
###############################################################################
prompt_reboot() {
    echo -ne "Reboot now? (Y/N): "
    read -r ans
    case "$ans" in
        [Yy]*)
            info "Rebooting..."
            sudo reboot
            ;;
        *)
            info "Reboot skipped."
            ;;
    esac
}

###############################################################################
# INSTALL
###############################################################################
install_macros() {
    info "=== INSTALL: Klipper-Service-Macros $VERSION ==="

    mkdir -p "$CONFIG_DIR"

    if [[ -d "$REPO_DIR/.git" ]]; then
        info "Existing repo found. Pulling latest for branch $VERSION..."
        git -C "$REPO_DIR" fetch
        git -C "$REPO_DIR" checkout "$VERSION"
        git -C "$REPO_DIR" pull
    else
        info "Cloning repo (branch $VERSION)..."
        git clone -b "$VERSION" "$REPO_URL" "$REPO_DIR"
    fi

    mirror_structure
    merge_settings
    add_update_manager

    info "Restarting Moonraker & Klipper..."
    sudo systemctl restart moonraker || warn "Moonraker restart failed or not present."
    sudo systemctl restart klipper || warn "Klipper restart failed or not present."

    info "=== INSTALL COMPLETE ==="
    prompt_reboot
}

###############################################################################
# UPDATE
###############################################################################
update_macros() {
    info "=== UPDATE: Klipper-Service-Macros $VERSION ==="

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        warn "No existing repo found. Running full install..."
        install_macros
        return
    fi

    git -C "$REPO_DIR" fetch
    git -C "$REPO_DIR" checkout "$VERSION"
    git -C "$REPO_DIR" pull

    mirror_structure
    merge_settings
    add_update_manager

    info "Restarting Moonraker & Klipper..."
    sudo systemctl restart moonraker || warn "Moonraker restart failed or not present."
    sudo systemctl restart klipper || warn "Klipper restart failed or not present."

    info "=== UPDATE COMPLETE ==="
    prompt_reboot
}

###############################################################################
# UNINSTALL
###############################################################################
uninstall_macros() {
    info "=== UNINSTALL: Klipper-Service-Macros ==="

    rm -rf "$MACRO_DIR" || true
    rm -rf "$REPO_DIR" || true

    if [[ -f "$MOONRAKER_CONF" ]]; then
        sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF" || true
        info "Removed [update_manager $UPDATE_NAME] from moonraker.conf."
    fi

    if [[ -f "$MOONRAKER_ASVC" ]]; then
        sed -i '/^[[:space:]]*service_macros[[:space:]]*$/d' "$MOONRAKER_ASVC" || true
        info "Removed service_macros from moonraker.asvc."
    fi

    sudo systemctl restart moonraker || warn "Moonraker restart failed or not present."
    sudo systemctl restart klipper || warn "Klipper restart failed or not present."

    info "=== UNINSTALL COMPLETE ==="
    prompt_reboot
}

###############################################################################
# MAIN ENTRYPOINT
###############################################################################
case "${1:-}" in
    install)   install_macros ;;
    update)    update_macros ;;
    uninstall) uninstall_macros ;;
    *)
        echo "Usage: $0 {install|update|uninstall}"
        ;;
esac
