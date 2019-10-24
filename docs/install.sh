#!/usr/bin/env bash

set -eu -o pipefail

# Surrounding in brackets ensures that the whole install script runs
# and not just a part of it if there's a strange partial download or
# buffering issue.
{

# Let's make some pretty stuff
COLOR_RESET="$(tput sgr0)"
COLOR_BLACK="$(tput setaf 0)"
COLOR_RED="$(tput setaf 1)"
COLOR_GREEN="$(tput setaf 2)"
COLOR_YELLOW="$(tput setaf 3)"
COLOR_BLUE="$(tput setaf 4)"
COLOR_MAGENTA="$(tput setaf 5)"
COLOR_CYAN="$(tput setaf 6)"
COLOR_WHITE="$(tput setaf 7)"
SYMBOL_TICK="✔"
SYMBOL_CROSS="✖"
SYMBOL_WARN="⚠"

GITHUB_FILE_PATH="https://raw.githubusercontent.com/devopsmakers/macstrap/master/files/"

detect_profile() {
    local DETECTED_PROFILE
    DETECTED_PROFILE=''
    local SHELLTYPE
    SHELLTYPE="$(basename "/$SHELL")"

    if [ "$SHELLTYPE" = "bash" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            DETECTED_PROFILE="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            DETECTED_PROFILE="$HOME/.bash_profile"
        fi
    elif [ "$SHELLTYPE" = "zsh" ]; then
        DETECTED_PROFILE="$HOME/.zshrc"
    fi

    if [ ! -z "$DETECTED_PROFILE" ]; then
        echo "$DETECTED_PROFILE"
    fi
}

ensure_bin_dirs() {
    if [ ! -d "$HOME/.bin" ]; then
        echo "${COLOR_YELLOW}${SYMBOL_WARN}${COLOR_WHITE} Missing user bin directory. Attempting to create${COLOR_RESET}"
        mkdir -p "$HOME/.bin"
        chmod 0700 "$HOME/.bin"
        chown $USER:admin "$HOME/.bin"
    fi
    if [ ! -d "$HOME/.macstrap" ]; then
        echo "${COLOR_YELLOW}${SYMBOL_WARN}${COLOR_WHITE} Missing user macstrap config directory. Attempting to create${COLOR_RESET}"
        mkdir -p "$HOME/.macstrap"
        chmod 0700 "$HOME/.macstrap"
        chown $USER:admin "$HOME/.macstrap"
    fi
    if [ ! -d "/usr/local/bin" ]; then
        echo "${COLOR_YELLOW}${SYMBOL_WARN}${COLOR_WHITE} Missing install directory. Attempting to create, will prompt for your admin password:${COLOR_RESET}"
        local USER="$(whoami)"
        sudo mkdir /usr/local/bin
        sudo chmod 0775 /usr/local/bin
        sudo chown $USER:admin /usr/local/bin
    fi
}

ensure_xcode() {
    xcode-select --install 2>/dev/null || echo "${COLOR_GREEN}${SYMBOL_TICK}${COLOR_RESET} XCode tools installed"
}

grab_file() {
    if [ -f "${HOME}/$1" ]; then
        mv -f "${HOME}/$1" "${HOME}/$1.bak"
    fi
    echo "${COLOR_GREEN}${SYMBOL_TICK}${COLOR_RESET} Fetching file: $1"
    curl -fsS "${GITHUB_FILE_PATH}/$1" -o "${HOME}/$1"
    set +u
    if [ ! -z $2 ]; then
        chmod $2 "${HOME}/$1"
    fi
    set -u
}

install_homebrew() {
    brew --version || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

install_zsh() {
    /usr/local/bin/brew install zsh
    grep -q /usr/local/bin/zsh /etc/shells || sudo -s 'echo /usr/local/bin/zsh >> /etc/shells'
    chsh -s /usr/local/bin/zsh
    if [ ! -d "${HOME}/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    fi
    if [ ! -d "${HOME}/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    fi
}

install_iterm2() {
    if [ ! -d /Applications/iTerm.app ]; then
        brew cask install iterm2
    fi
    curl -fsS https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/Meslo/S/Regular/complete/Meslo%20LG%20S%20Regular%20Nerd%20Font%20Complete.ttf -o "/Library/Fonts/MesloLGS NF.ttf"
}

function iterm_run_macstrap() {
    osascript &>/dev/null <<EOF
        tell application "iTerm"
            activate
            set term to (make new terminal)
            tell term
                launch session "Default Session"
                tell the last session
                    delay 1
                    write text "macstrap -H"
                end
            end
        end tell
EOF
}

install_main() {
    ensure_bin_dirs
    ensure_xcode

    install_homebrew
    install_zsh
    install_iterm2

    # Get the files that we want to install to $HOME
    grab_file ".zshrc" "0700"
    grab_file ".p10k.zsh" "0700"
    grab_file ".myrc" "0700"
    grab_file ".bin/macstrap" "0500"
    grab_file ".bin/open" "0500"
    grab_file ".macstrap/config.json"
    grab_file "Library/Preferences/com.googlecode.iterm2.plist"

    echo "Install completed."
    echo ""
    echo "Note: Some tools will require a new terminal window"
    echo ""

    set +u
    if [ -z $UP ]; then
        iterm_run_macstrap
    fi
    set -u

    shell_reset
}

shell_reset() {
    unset -f detect_profile ensure_bin_dirs ensure_xcode install_homebrew install_zsh install_iterm2 grab_file install_main shell_reset iterm_run_macstrap
}

install_main

}
