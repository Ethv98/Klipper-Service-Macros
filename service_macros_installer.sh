#!/bin/bash
#
# Klipper-Service-Macros Installer / Updater / Uninstaller
# Uses /Configuration directory and installs symlink as "Service Config"
# Repo: https://github.com/Herculez3D/Klipper-Service-Macros
#

set -euo pipefail

REPO_URL="https://github.com/Herculez3D/Klipper-Service-Macros.git"
REPO_DIR="$HOME/Klipper-Service-Macros"

CONFIG_DIR="$HOME/printer_data/config"
MACRO_DIR="$CONFIG_DIR/Service Config"                       # NEW NAME HERE
USER_SETTINGS="$CONFIG_DIR/ServiceSettings.cfg"              # editable
REPO_SETTINGS="$REPO_DIR/Configuration/ServiceSettings.cfg"  # template

MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
UPDATE_NAME="service_macros"


###############################################################################
# MERGE NEW DEFAULT SETTINGS INTO USER SETTINGS
###############################################################################
merge_settings() {
    if [[ ! -f "$USER_SETTINGS" ]]; then
        echo "No user settings found — copying defaults."
        cp "$REPO_SETTINGS" "$USER_SETTINGS"
        return
    fi

    echo "Merging new defaults into user settings..."

    TEMP_MERGED="/tmp/ServiceSettings_merged.cfg"

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
    ' "$USER_SETTINGS" "$REPO_SETTINGS" > "$TEMP_MERGED"

    mv "$TEMP_MERGED" "$USER_SETTINGS"
}


###############################################################################
# CREATE SYMLINK: ~/printer_data/config/Service Config → repo /Configuration
###############################################################################
create_symlink() {
    echo "Creating symlink for Service Config..."

    rm -rf "$MACRO_DIR"
    ln -s "$REPO_DIR/Configuration" "$MACRO_DIR"

    echo "Symlink created:"
    echo "\"$MACRO_DIR\" → $REPO_DIR/Configuration"
}


###############################################################################
# ADD MOONRAKER UPDATE MANAGER SUPPORT
###############################################################################
add_update_manager() {
    echo "Configuring Moonraker update manager..."

    if grep -q "^\[update_manager $UPDATE_NAME\]" "$MOONRAKER_CONF" 2>/dev/null; then
        echo "Update manager entry already exists."
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

    echo "Added update_manager entry."
}


###############################################################################
# INSTALL ROUTINE
###############################################################################
install_macros() {
    echo "=== INSTALLING KLIPPER SERVICE MACROS ==="

    if [[ -d "$REPO_DIR/.git" ]]; then
        echo "Repository already exists — updating..."
        git -C "$REPO_DIR" pull
    else
        echo "Cloning repository..."
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    create_symlink
    merge_settings
    add_update_manager

    echo "Restarting Moonraker + Klipper..."
    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    echo "=== INSTALL COMPLETE ==="
}


###############################################################################
# UPDATE ROUTINE
###############################################################################
update_macros() {
    echo "=== UPDATING KLIPPER SERVICE MACROS ==="

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        echo "No repo found — running installer..."
        install_macros
        return
    fi

    git -C "$REPO_DIR" pull
    create_symlink
    merge_settings

    echo "Restarting services..."
    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    echo "=== UPDATE COMPLETE ==="
}


###############################################################################
# UNINSTALL ROUTINE
###############################################################################
uninstall_macros() {
    echo "=== UNINSTALLING KLIPPER SERVICE MACROS ==="

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
