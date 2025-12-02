#!/bin/bash
#
# Klipper-Service-Macros Installer / Updater / Uninstaller
# Adds reboot prompt (Y/N) instead of --reboot flag
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
UPDATE_NAME="service_macros"

info() { echo -e "\e[32m[INFO]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
error() { echo -e "\e[31m[ERROR]\e[0m $1"; exit 1; }

normalize_includes() {
    if [[ ! -f "$USER_SETTINGS" ]]; then return; fi

    sed -i '/\[include .*ServiceMacros\/ServiceMacros.cfg]/d' "$USER_SETTINGS"
    sed -i '/\[include .*\.\/ServiceMacros\/ServiceMacros.cfg]/d' "$USER_SETTINGS"

    sed -i '1i [include ServiceMacros/ServiceMacros.cfg]' "$USER_SETTINGS"
    info "Normalized include line."
}

merge_settings() {
    if [[ ! -f "$REPO_SETTINGS" ]]; then
        error "Template settings missing: $REPO_SETTINGS"
    fi

    if [[ ! -f "$USER_SETTINGS" ]]; then
        info "Installing default settings..."
        cp "$REPO_SETTINGS" "$USER_SETTINGS"
        normalize_includes
        return
    fi

    info "Merging user settings with template..."

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

create_symlink() {
    info "Creating symlink for ServiceMacros..."

    if [[ -e "$MACRO_DIR" || -L "$MACRO_DIR" ]]; then
        warn "Removing old ServiceMacros entry..."
        rm -rf "$MACRO_DIR"
    fi

    mkdir -p "$REPO_DIR/Configuration"

    ln -s "$REPO_DIR/Configuration" "$MACRO_DIR"
    info "Symlink created: $MACRO_DIR → $REPO_DIR/Configuration"
}

add_update_manager() {
    info "Configuring Moonraker update_manager..."

    if [[ -f "$MOONRAKER_CONF" ]] && grep -q "^\[update_manager $UPDATE_NAME\]" "$MOONRAKER_CONF"; then
        warn "Entry already exists."
        return
    fi

    cat <<EOF >> "$MOONRAKER_CONF"

[update_manager $UPDATE_NAME]
type: git_repo
path: $REPO_DIR
origin: $REPO_URL
install_script: service_macros_installer.sh install
update_script: service_macros_installer.sh update
EOF

    info "Moonraker update entry added."
}

prompt_reboot() {
    echo -ne "\nWould you like to reboot now? (Y/N): "
    read -r answer
    case "$answer" in
        [Yy]* )
            info "Rebooting..."
            sudo reboot
            ;;
        * )
            info "Reboot skipped."
            ;;
    esac
}

install_macros() {
    info "=== INSTALLING Klipper-Service-Macros ==="

    mkdir -p "$CONFIG_DIR"

    if [[ -d "$REPO_DIR/.git" ]]; then
        info "Updating existing repo..."
        git -C "$REPO_DIR" pull
    else
        info "Cloning repository..."
        git clone "$REPO_URL" "$REPO_DIR"
    fi

    create_symlink
    merge_settings
    add_update_manager

    info "Restarting Moonraker & Klipper..."
    sudo systemctl restart moonraker || warn "Moonraker restart failed."
    sudo systemctl restart klipper || warn "Klipper restart failed."

    info "=== INSTALL COMPLETE ==="
    prompt_reboot
}

update_macros() {
    info "=== UPDATING Klipper-Service-Macros ==="

    if [[ ! -d "$REPO_DIR/.git" ]]; then
        warn "No installation found, switching to install..."
        install_macros
        return
    fi

    git -C "$REPO_DIR" pull
    create_symlink
    merge_settings

    sudo systemctl restart moonraker || warn "Moonraker restart failed."
    sudo systemctl restart klipper || warn "Klipper restart failed."

    info "=== UPDATE COMPLETE ==="
    prompt_reboot
}

uninstall_macros() {
    info "=== UNINSTALLING Klipper-Service-Macros ==="

    rm -rf "$MACRO_DIR"
    rm -rf "$REPO_DIR"

    if [[ -f "$MOONRAKER_CONF" ]]; then
        sed -i "/^\[update_manager $UPDATE_NAME\]/,/^$/d" "$MOONRAKER_CONF"
        info "Removed update_manager entry."
    fi

    sudo systemctl restart moonraker || warn "Moonraker restart failed."
    sudo systemctl restart klipper || warn "Klipper restart failed."

    info "=== UNINSTALL COMPLETE ==="
    prompt_reboot
}

case "${1:-}" in
    install) install_macros ;;
    update) update_macros ;;
    uninstall) uninstall_macros ;;
    *)
        echo "Usage: $0 {install|update|uninstall}"
        ;;
esac
