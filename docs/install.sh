#!/usr/bin/env bash

# Surrounding in brackets ensures that the whole script gets loaded to memory
# before running which allows us to update the script from the script without
# issue.
{
set -eu -o pipefail

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
TEXT_BOLD="$(tput bold)"
SYMBOL_TICK="✔"
SYMBOL_CROSS="✖"
SYMBOL_WARN="⚠"
SYMBOL_DEBUG="⚲"
SYMBOL_INFO="ⓘ"

log_debug() {
    if [ ${DEBUG:-0} -eq 1 ]; then
        echo "${COLOR_RESET}${SYMBOL_DEBUG} $@ ${COLOR_RESET}"
    fi
}

log_info() {
    echo "${COLOR_CYAN}${SYMBOL_INFO} $@ ${COLOR_RESET}"
}

log_ok() {
    echo "${COLOR_GREEN}${SYMBOL_TICK} $@ ${COLOR_RESET}"
}

log_warn() {
    echo "${COLOR_YELLOW}${SYMBOL_WARN} $@ ${COLOR_RESET}"
}

log_err() {
    echo "${TEXT_BOLD}${COLOR_RED}${SYMBOL_CROSS} $@ ${COLOR_RESET}"
}

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
        log_warn "Missing user bin directory. Attempting to create"
        mkdir -p "$HOME/.bin"
        chmod 0700 "$HOME/.bin"
        chown $USER:admin "$HOME/.bin"
    fi
    if [ ! -d "$HOME/.macstrap" ]; then
        log_warn "Missing user macstrap config directory. Attempting to create"
        mkdir -p "$HOME/.macstrap"
        chmod 0700 "$HOME/.macstrap"
        chown $USER:admin "$HOME/.macstrap"
    fi
    if [ ! -d "/usr/local/bin" ]; then
        log_warn "Missing install directory. Attempting to create, will prompt for your admin password:"
        local USER="$(whoami)"
        sudo mkdir /usr/local/bin
        sudo chmod 0775 /usr/local/bin
        sudo chown $USER:admin /usr/local/bin
    fi
}

ensure_xcode() {
    xcode-select --install 2>/dev/null || log_ok "XCode tools installed"
}

grab_file() {
    if [ -f "${HOME}/$1" ]; then
        mv -f "${HOME}/$1" "${HOME}/$1.bak"
    fi
    curl --connect-timeout 5 -fsS "${GITHUB_FILE_PATH}/$1" -o "${HOME}/$1" && log_ok "File: $1" || (log_err "File: $1" && exit 1)
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
    echo $SHELL | grep -q "/usr/local/bin/zsh" || chsh -s /usr/local/bin/zsh
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
        	create window with default profile
        	tell current session of current window
        		delay 2
        		write text "macstrap -H"
        	end tell
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
    grab_file ".bin/semver" "0500"
    grab_file ".macstrap/config.json"
    grab_file "Library/Preferences/com.googlecode.iterm2.plist"

    log_ok "Install complete 🎉"
    echo ""

    set +u
    if [ -z $UP ]; then
        log_info "Opening iTerm2 to run macstrap"
        iterm_run_macstrap
    fi
    set -u
    echo ""
    shell_reset
}

shell_reset() {
    unset -f log_ok log_warn log_err detect_profile ensure_bin_dirs ensure_xcode \
        install_homebrew install_zsh install_iterm2 grab_file install_main \
        shell_reset iterm_run_macstrap
}

install_main

}
