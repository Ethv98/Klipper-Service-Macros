#!/bin/bash
#
# Klipper-Service-Macros Installer / Updater / Uninstaller
# Restored functioning version using /ServiceMacros folder
#

set -euo pipefail

# Detect actual user's home directory (pi, voron, mainsail, fluidd, etc)
USER_HOME="$(getent passwd $(whoami) | cut -d: -f6)"

REPO_URL="https://github.com/Herculez3D/Klipper-Service-Macros.git"
REPO_DIR="$USER_HOME/Klipper-Service-Macros"

CONFIG_DIR="$USER_HOME/printer_data/config"
MACRO_DIR="$CONFIG_DIR/ServiceMacros"                      # <─ WORKING FOLDER NAME
USER_SETTINGS="$CONFIG_DIR/ServiceSettings.cfg"
REPO_SETTINGS="$REPO_DIR/Configuration/ServiceSettings.cfg"

MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
UPDATE_NAME="service_macros"


###############################################################################
# MERGE SETTINGS
###############################################################################
merge_settings() {
    if [[ ! -f "$USER_SETTINGS" ]]; then
        echo "Installing new user settings..."
        cp "$REPO_SETTINGS" "$USER_SETTINGS"
        return
    fi

    echo "Merging settings..."
    TEMP_MERGED="/tmp/ServiceSettings_merged.cfg"

    awk '
        FNR==NR { 
            if ($0 ~ /^\[/) section=$0; 
            if ($0 ~ /=/) existing[section,$1]=$0; 
            next 
        }
        {
            if ($0 ~ /^\[/) section=$0;
            if ($0 ~ /=/) {
                key=$1;
                if ((section,key) in existing)
                    print existing[section,key];
                else
                    print $0;
            } else print $0;
        }
    ' "$USER_SETTINGS" "$REPO_SETTINGS" > "$TEMP_MERGED"

    mv "$TEMP_MERGED" "$USER_SETTINGS"
}


###############################################################################
# CREATE SYMLINK: ~/printer_data/config/ServiceMacros → ~/Klipper-Service-Macros/Configuration
###############################################################################
create_symlink() {
    echo "Creating ServiceMacros symlink..."

    rm -rf "$MACRO_DIR"
    ln -s "$REPO_DIR/Configuration" "$MACRO_DIR"

    echo "Symlink created: $MACRO_DIR → $REPO_DIR/Configuration"
}


###############################################################################
# MOONRAKER UPDATE MANAGER ENTRY
###############################################################################
add_update_manager() {
    echo "Configuring Moonraker update manager..."

    if [[ -f "$MOONRAKER_CONF" ]] && grep -q "^\[update_manager $UPDATE_NAME\]" "$MOONRAKER_CONF"; then
        echo "update_manager entry already exists."
        return
    fi

    cat <<EOF >> "$MOONRAKER_CONF"

[update_manager $UPDATE_NAME]
type: git_repo
path: $REPO_DIR
origin: $REPO_URL
install_script: service_macros_installer.sh install
update_script: service_macros_installer.sh update
uninstall_script: service_macros_installer.sh uninstall
EOF
}


###############################################################################
# INSTALL ROUTINE
###############################################################################
install_macros() {
    echo "=== INSTALLING Klipper-Service-Macros ==="

    if [[ -d "$REPO_DIR/.git" ]]; then
        echo "Repository exists — updating..."
        git -C "$REPO_DIR" pull
    else
        echo "Cloning repository to: $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    create_symlink
    merge_settings
    add_update_manager

    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    echo "=== INSTALL COMPLETE ==="
}


###############################################################################
# UPDATE ROUTINE
###############################################################################
update_macros() {
    echo "=== UPDATING Klipper-Service-Macros ==="

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "No installation detected — running install."
        install_macros
        return
    fi

    git -C "$REPO_DIR" pull
    create_symlink
    merge_settings

    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    echo "=== UPDATE COMPLETE ==="
}


###############################################################################
# UNINSTALL ROUTINE
###############################################################################
uninstall_macros() {
    echo "=== UNINSTALLING Klipper-Service-Macros ==="

    rm -rf "$MACRO_DIR"
    rm -rf "$REPO_DIR"

    sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF" || true

    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    echo "=== UNINSTALL COMPLETE ==="
}


###############################################################################
# MAIN HANDLER
###############################################################################
case "${1:-}" in
    install) install_macros ;;
    update) update_macros ;;
    uninstall) uninstall_macros ;;
    *)
        echo "Usage: $0 {install|update|uninstall}"
        ;;
esac
