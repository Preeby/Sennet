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
    local package_name

    case $dep in
        "dnsutils" | "bind-tools")
            case $DISTRIBUTION in
                "debian" | "ubuntu" | "kali" | "raspbian")
                    package_name="dnsutils"
                    ;;
                "fedora" | "centos" | "redhat")
                    package_name="bind-utils"
                    ;;
                "arch" | "manjaro" | "antergos" | "artix")
                    package_name="bind-tools"
                    ;;
                *)
                    error "Unknown Linux distribution! Please install the required dependencies manually."
                    ;;
            esac
            ;;
        *)
            package_name=$dep
            ;;
    esac

    if [ -x "/usr/bin/$dep" ]; then
        log "$dep is already installed."
        return 0  # Dependency is installed
    else
        log "$dep is not installed. Trying to install $package_name."
        install_package "$package_name"
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
        "debian" | "ubuntu" | "kali" | "raspbian")
            apt-get update
            apt-get install -y $package
            ;;
        "fedora" | "centos" | "redhat")
            dnf install -y $package
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

# List of dependencies
dependencies=('nmap' 'hping' 'dnsutils' 'iw')
# Install these if it doesn't automatically!

for dep in "${dependencies[@]}"; do
    check_dependency "$dep"
done

# List of commands to install
commands=('netdos' 'netpulse' 'sennet' 'sennet_update' 'sennet_version')

for cmd in "${commands[@]}"; do
    chmod +x Commands/$cmd
    sudo mv Commands/$cmd /usr/local/bin/
done

log "Installation complete!"
