#!/bin/bash

log() {
    echo "[INFO] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root (use sudo)."
    fi
}

check_dependency() {
    local dep=$1

    if command -v "$dep" &>/dev/null; then
        log "$dep is already installed."
        return 0
    else
        log "$dep is not installed. Trying to install $dep."
        install_package "$dep"
    fi
}

detect_distribution() {
    if [ -f "/etc/os-release" ]; then
        source /etc/os-release
        DISTRIBUTION=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    elif [ -f "/etc/redhat-release" ]; then
        DISTRIBUTION="redhat"
    else
        DISTRIBUTION=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
}

install_package() {
    local package=$1

    case $DISTRIBUTION in
        "debian" | "ubuntu" | "kali" | "raspbian" | "fedora" | "centos" | "redhat")
            package_manager=$(command -v apt-get || command -v dnf)
            $package_manager update
            $package_manager install -y $package
            ;;
        "arch" | "manjaro" | "antergos" | "artix")
            pacman -Syu --noconfirm $package
            ;;
        *)
            error "Unknown Linux distribution! Please install the required dependencies manually."
            ;;
    esac
}

check_root
detect_distribution

REPO_URL="https://github.com/Preeby/Sennet"
RELEASE_TAG=$( l -sI "${REPO_URL}/releases/latest" | grep -i 'location' | awk -F '/' '{print $NF}' | tr -d '\r\n')

dependencies=('nmap' 'hping3' 'dnsutils' 'iw' 'whois')

# Install these if it doesn't automatically!
for dep in "${dependencies[@]}"; do
    check_dependency "$dep"
done

commands=('netdos' 'netpulse' 'sennet' 'sennet_update' 'sennet_version' 'sennet_uninstall')

for cmd in "${commands[@]}"; do
    chmod +x "Commands/$cmd"

    if [ -w "/usr/local/bin" ]; then
        sudo mv "Commands/$cmd" "/usr/local/bin/"
    elif [ -w "$HOME/bin" ]; then
        mv "Commands/$cmd" "$HOME/bin/"
    else
        error "Unable to install commands. Add $HOME/bin to your PATH or choose another writable directory manually."
    fi
done

log "Installation complete!"

target_directory=$(pwd)

sudo rm -r $target_directory

cd ~

echo "Cleanup completed."
