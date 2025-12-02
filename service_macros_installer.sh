#!/bin/bash
#
# Klipper-Service-Macros Installer / Updater / Uninstaller
# Corrected symlink behavior, update_manager support, improved logging,
# optional reboot, and universal user home detection.
#

set -euo pipefail

# Auto-detect user's home directory (works for pi, voron, mainsail, fluidd, etc)
USER_HOME="$(getent passwd $(whoami) | cut -d: -f6)"

REPO_URL="https://github.com/Herculez3D/Klipper-Service-Macros.git"
REPO_DIR="$USER_HOME/Klipper-Service-Macros"

CONFIG_DIR="$USER_HOME/printer_data/config"
MACRO_DIR="$CONFIG_DIR/ServiceMacros"
USER_SETTINGS="$CONFIG_DIR/ServiceSettings.cfg"
REPO_SETTINGS="$REPO_DIR/Configuration/ServiceSettings.cfg"

MOONRAKER_CONF="$CONFIG_DIR/moonraker.conf"
UPDATE_NAME="service_macros"

REBOOT_AFTER=false
[[ "${2:-}" == "--reboot" ]] && REBOOT_AFTER=true


################################################################################
# LOGGING UTILITIES
################################################################################
info() { echo -e "\e[32m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }


################################################################################
# MERGE SETTINGS
################################################################################
merge_settings() {
    info "Checking user settings..."

    if [[ ! -f "$USER_SETTINGS" ]]; then
        info "No user settings found. Installing defaults..."
        cp "$REPO_SETTINGS" "$USER_SETTINGS"
        return
    fi

    info "Merging new defaults with existing user settings..."

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
    info "User settings updated."
}


################################################################################
# CREATE SYMLINK
################################################################################
create_symlink() {
    info "Creating symlink at: $MACRO_DIR"

    # Remove any prior incorrect file/symlink
    if [[ -e "$MACRO_DIR" ]]; then
        warn "Previous ServiceMacros detected. Removing it..."
        rm -rf "$MACRO_DIR"
    fi

    # Guarantee Configuration folder exists
    mkdir -p "$REPO_DIR/Configuration"

    # Create symlink
    ln -s "$REPO_DIR/Configuration" "$MACRO_DIR"

    info "Symlink created:"
    echo " → $MACRO_DIR -> $REPO_DIR/Configuration"
}


################################################################################
# MOONRAKER UPDATE MANAGER
################################################################################
add_update_manager() {
    info "Configuring Moonraker update manager..."

    if [[ -f "$MOONRAKER_CONF" ]] && grep -q "^\[update_manager $UPDATE_NAME\]" "$MOONRAKER_CONF"; then
        warn "Update manager entry already exists."
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

    info "Moonraker update manager entry added."
}


################################################################################
# INSTALL ROUTINE
################################################################################
install_macros() {
    info "Starting installation of Klipper-Service-Macros..."

    if [[ -d "$REPO_DIR/.git" ]]; then
        info "Repository exists. Pulling latest changes..."
        git -C "$REPO_DIR" pull
    else
        info "Cloning repository into: $REPO_DIR"
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    create_symlink
    merge_settings
    add_update_manager

    info "Restarting Moonraker & Klipper..."
    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    info "Installation complete!"

    if $REBOOT_AFTER; then
        info "Rebooting system in 5 seconds..."
        sleep 5
        sudo reboot
    fi
}


################################################################################
# UPDATE ROUTINE
################################################################################
update_macros() {
    info "Updating Klipper-Service-Macros..."

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        warn "No installation found. Installing now..."
        install_macros
        return
    fi

    git -C "$REPO_DIR" pull
    create_symlink
    merge_settings

    info "Restarting Moonraker & Klipper..."
    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    info "Update complete!"
}


################################################################################
# UNINSTALL ROUTINE
################################################################################
uninstall_macros() {
    info "Uninstalling Klipper-Service-Macros..."

    rm -rf "$MACRO_DIR"
    rm -rf "$REPO_DIR"

    sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF" || true

    info "Restarting Moonraker & Klipper..."
    sudo systemctl restart moonraker || true
    sudo systemctl restart klipper || true

    info "Uninstall complete!"
}


################################################################################
# MAIN HANDLER
################################################################################
case "${1:-}" in
    install) install_macros ;;
    update) update_macros ;;
    uninstall) uninstall_macros ;;
    *)
        echo "Usage: $0 {install|update|uninstall} [--reboot]"
        ;;
esac
