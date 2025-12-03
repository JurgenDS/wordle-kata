#!/bin/sh
#
# Cross-Platform Security Tools Setup Script
# Installs gitleaks and semgrep for secret scanning and SAST
#
# Supported platforms:
#   - macOS (via Homebrew)
#   - Linux (via package manager or direct download)
#   - Windows (via WSL, winget, scoop, or chocolatey)
#

set -e

# Colors for output (POSIX-compliant)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    printf "\n${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}\n"
    printf "${BLUE}${BOLD}  %s${NC}\n" "$1"
    printf "${BLUE}${BOLD}═══════════════════════════════════════════════════════════════${NC}\n\n"
}

print_step() {
    printf "${CYAN}▶ %s${NC}\n" "$1"
}

print_success() {
    printf "${GREEN}✓ %s${NC}\n" "$1"
}

print_failure() {
    printf "${RED}✗ %s${NC}\n" "$1"
}

print_warning() {
    printf "${YELLOW}⚠ %s${NC}\n" "$1"
}

print_info() {
    printf "${CYAN}ℹ %s${NC}\n" "$1"
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            OS="macos"
            ;;
        Linux*)
            OS="linux"
            # Detect Linux distribution
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                DISTRO="$ID"
            elif [ -f /etc/debian_version ]; then
                DISTRO="debian"
            elif [ -f /etc/redhat-release ]; then
                DISTRO="rhel"
            else
                DISTRO="unknown"
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="windows"
            ;;
        *)
            OS="unknown"
            ;;
    esac
}

# Check if a command exists
command_exists() {
    command -v "$1" > /dev/null 2>&1
}

# Install gitleaks
install_gitleaks() {
    print_step "Installing gitleaks..."

    if command_exists gitleaks; then
        print_success "gitleaks is already installed ($(gitleaks version 2>/dev/null || echo 'version unknown'))"
        return 0
    fi

    case "$OS" in
        macos)
            if command_exists brew; then
                brew install gitleaks
            else
                print_failure "Homebrew not found. Please install Homebrew first:"
                printf "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"\n"
                return 1
            fi
            ;;
        linux)
            case "$DISTRO" in
                ubuntu|debian|pop|mint|elementary)
                    # Try apt if available, otherwise use direct download
                    if command_exists apt-get; then
                        print_info "Installing via direct download (gitleaks not in apt repos)..."
                        install_gitleaks_binary
                    fi
                    ;;
                fedora|rhel|centos|rocky|alma)
                    if command_exists dnf; then
                        sudo dnf install -y gitleaks 2>/dev/null || install_gitleaks_binary
                    else
                        install_gitleaks_binary
                    fi
                    ;;
                arch|manjaro|endeavouros)
                    if command_exists pacman; then
                        sudo pacman -S --noconfirm gitleaks 2>/dev/null || install_gitleaks_binary
                    else
                        install_gitleaks_binary
                    fi
                    ;;
                alpine)
                    if command_exists apk; then
                        sudo apk add gitleaks 2>/dev/null || install_gitleaks_binary
                    else
                        install_gitleaks_binary
                    fi
                    ;;
                *)
                    install_gitleaks_binary
                    ;;
            esac
            ;;
        windows)
            if command_exists winget; then
                winget install --id Gitleaks.Gitleaks -e
            elif command_exists scoop; then
                scoop install gitleaks
            elif command_exists choco; then
                choco install gitleaks -y
            else
                print_failure "No supported package manager found (winget, scoop, or chocolatey)"
                print_info "Please install one of the following:"
                printf "  - winget (included in Windows 11 and Windows 10 App Installer)\n"
                printf "  - scoop: https://scoop.sh\n"
                printf "  - chocolatey: https://chocolatey.org\n"
                return 1
            fi
            ;;
        *)
            print_failure "Unsupported operating system"
            return 1
            ;;
    esac

    if command_exists gitleaks; then
        print_success "gitleaks installed successfully"
    else
        print_failure "gitleaks installation failed"
        return 1
    fi
}

# Install gitleaks binary directly (for Linux distros without package)
install_gitleaks_binary() {
    print_info "Downloading gitleaks binary..."

    GITLEAKS_VERSION="8.21.2"
    ARCH=$(uname -m)

    case "$ARCH" in
        x86_64|amd64)
            ARCH="x64"
            ;;
        aarch64|arm64)
            ARCH="arm64"
            ;;
        armv7l)
            ARCH="armv7"
            ;;
        *)
            print_failure "Unsupported architecture: $ARCH"
            return 1
            ;;
    esac

    DOWNLOAD_URL="https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_${ARCH}.tar.gz"

    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"

    if command_exists curl; then
        curl -sSL "$DOWNLOAD_URL" -o gitleaks.tar.gz
    elif command_exists wget; then
        wget -q "$DOWNLOAD_URL" -O gitleaks.tar.gz
    else
        print_failure "Neither curl nor wget found"
        return 1
    fi

    tar -xzf gitleaks.tar.gz

    # Install to /usr/local/bin or ~/.local/bin
    if [ -w /usr/local/bin ]; then
        mv gitleaks /usr/local/bin/
    elif [ -d "$HOME/.local/bin" ]; then
        mv gitleaks "$HOME/.local/bin/"
        print_info "Installed to ~/.local/bin - make sure it's in your PATH"
    else
        mkdir -p "$HOME/.local/bin"
        mv gitleaks "$HOME/.local/bin/"
        print_warning "Added to ~/.local/bin - add this to your PATH:"
        printf "  export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
    fi

    cd - > /dev/null
    rm -rf "$TMP_DIR"
}

# Install semgrep
install_semgrep() {
    print_step "Installing semgrep..."

    if command_exists semgrep; then
        print_success "semgrep is already installed ($(semgrep --version 2>/dev/null | head -1 || echo 'version unknown'))"
        return 0
    fi

    case "$OS" in
        macos)
            if command_exists brew; then
                brew install semgrep
            elif command_exists pip3; then
                pip3 install semgrep
            else
                print_failure "Neither Homebrew nor pip3 found"
                return 1
            fi
            ;;
        linux)
            # Semgrep is best installed via pip on Linux
            if command_exists pip3; then
                pip3 install semgrep --user
            elif command_exists pip; then
                pip install semgrep --user
            elif command_exists python3; then
                python3 -m pip install semgrep --user
            else
                print_failure "Python pip not found. Please install Python 3 and pip first:"
                case "$DISTRO" in
                    ubuntu|debian|pop|mint)
                        printf "  sudo apt-get install python3-pip\n"
                        ;;
                    fedora|rhel|centos)
                        printf "  sudo dnf install python3-pip\n"
                        ;;
                    arch|manjaro)
                        printf "  sudo pacman -S python-pip\n"
                        ;;
                    alpine)
                        printf "  sudo apk add py3-pip\n"
                        ;;
                    *)
                        printf "  Install Python 3 and pip for your distribution\n"
                        ;;
                esac
                return 1
            fi
            ;;
        windows)
            if command_exists winget; then
                winget install --id Semgrep.Semgrep -e
            elif command_exists pip; then
                pip install semgrep
            elif command_exists pip3; then
                pip3 install semgrep
            else
                print_failure "No supported installation method found"
                print_info "Please install Python and pip, then run: pip install semgrep"
                return 1
            fi
            ;;
        *)
            print_failure "Unsupported operating system"
            return 1
            ;;
    esac

    # Check if installation succeeded (may need PATH refresh)
    if command_exists semgrep; then
        print_success "semgrep installed successfully"
    else
        print_warning "semgrep installed but not in PATH"
        print_info "You may need to restart your terminal or add ~/.local/bin to PATH"
    fi
}

# Install Java 21 (for SpotBugs compatibility)
check_java() {
    print_step "Checking Java version..."

    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
        if [ "$JAVA_VERSION" = "21" ]; then
            print_success "Java 21 is installed"
            return 0
        elif [ "$JAVA_VERSION" -ge 25 ] 2>/dev/null; then
            print_warning "Java $JAVA_VERSION detected - SpotBugs requires Java 21"
            print_info "Install Java 21 alongside your current version:"
            case "$OS" in
                macos)
                    printf "  brew install openjdk@21\n"
                    ;;
                linux)
                    case "$DISTRO" in
                        ubuntu|debian)
                            printf "  sudo apt-get install openjdk-21-jdk\n"
                            ;;
                        fedora|rhel|centos)
                            printf "  sudo dnf install java-21-openjdk-devel\n"
                            ;;
                        arch|manjaro)
                            printf "  sudo pacman -S jdk21-openjdk\n"
                            ;;
                        *)
                            printf "  Install OpenJDK 21 for your distribution\n"
                            ;;
                    esac
                    ;;
                windows)
                    printf "  winget install --id EclipseAdoptium.Temurin.21.JDK\n"
                    ;;
            esac
            return 0
        else
            print_success "Java $JAVA_VERSION is installed (compatible with SpotBugs)"
            return 0
        fi
    else
        print_warning "Java not found - required for backend builds"
        return 1
    fi
}

# Main
main() {
    printf "${BOLD}"
    printf "\n"
    printf "  ╔═══════════════════════════════════════════════════════════╗\n"
    printf "  ║                                                           ║\n"
    printf "  ║       SECURITY TOOLS SETUP                                ║\n"
    printf "  ║                                                           ║\n"
    printf "  ╚═══════════════════════════════════════════════════════════╝\n"
    printf "${NC}\n"

    print_header "DETECTING ENVIRONMENT"

    detect_os
    print_success "Operating System: $OS"
    if [ "$OS" = "linux" ]; then
        print_success "Distribution: $DISTRO"
    fi

    print_header "INSTALLING SECURITY TOOLS"

    GITLEAKS_OK=0
    SEMGREP_OK=0

    install_gitleaks && GITLEAKS_OK=1
    printf "\n"
    install_semgrep && SEMGREP_OK=1

    print_header "CHECKING PREREQUISITES"

    check_java

    print_header "SETUP SUMMARY"

    printf "${BOLD}%-30s %s${NC}\n" "Tool" "Status"
    printf "─────────────────────────────────────────────────\n"

    if [ "$GITLEAKS_OK" = "1" ] || command_exists gitleaks; then
        printf "%-30s ${GREEN}✓ Installed${NC}\n" "gitleaks (secret scanning)"
    else
        printf "%-30s ${RED}✗ Not installed${NC}\n" "gitleaks (secret scanning)"
    fi

    if [ "$SEMGREP_OK" = "1" ] || command_exists semgrep; then
        printf "%-30s ${GREEN}✓ Installed${NC}\n" "semgrep (SAST)"
    else
        printf "%-30s ${RED}✗ Not installed${NC}\n" "semgrep (SAST)"
    fi

    if command_exists java; then
        printf "%-30s ${GREEN}✓ Installed${NC}\n" "java (backend builds)"
    else
        printf "%-30s ${YELLOW}⚠ Not installed${NC}\n" "java (backend builds)"
    fi

    printf "\n"

    if [ "$GITLEAKS_OK" = "1" ] && [ "$SEMGREP_OK" = "1" ]; then
        printf "${GREEN}${BOLD}All security tools installed successfully!${NC}\n"
        printf "\nYou can now run the quality check:\n"
        printf "  ./quality-check.sh\n"
    else
        printf "${YELLOW}${BOLD}Some tools could not be installed automatically.${NC}\n"
        printf "Please install them manually using the instructions above.\n"
    fi

    printf "\n"
}

main "$@"
