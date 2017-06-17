set -e

if [[ `id -u` != 0 ]]
then
    echo "you are not root, how the hell do you think you can setup?"
    exit -1
fi

if [[ $# != 1 ]]
then
    echo "Usage: $0 <user>"
    exit -1
fi

USER="$1"
HOME_DIR="/home/$USER"
SCRIPT_RELATIVE_DIR=$(dirname "${BASH_SOURCE[0]}")
cwd=$(pwd)
cd "$SCRIPT_RELATIVE_DIR"
PROJ_DIR=$(pwd)
cd "$cwd"
CONFIGS_DIR="$PROJ_DIR/configs"
SCRIPTS_DIR="$PROJ_DIR/scripts"

confirm()
{
    if [[ "$2" == y ]]
    then
        do_it=1
        default="[Yn]"
    elif [[ "$2" == n ]]
    then
        do_it=0
        default="[yN]"
    else
        do_it=0
        default=
    fi

    echo -n "$1 $default: "
    read response

    if [[ ! -z "$response" ]]
    then
        if [ "$response" = "y" -o "$response" = "Y" ]
        then
            do_it=1
        else
            do_it=0
        fi
    fi

    if [[ "$do_it" == 1 ]]
    then
        eval "$3"
    fi
}

fast_install()
{
    apt-get --install-suggests -y --show-progress install $@
}
 
fast_purge()
{
    apt-get --install-suggests -y --show-progress purge $@
}

install_git()
{
    # cannot runit is shit for git in ubuntu 16.04, we must use the sysvinit instead
    fast_purge runit
    fast_purge git-all
    fast_purge git
    apt-get autoremove
    apt-get update
    fast_install git-daemon-sysvinit
    fast_install git
}

config_git()
{
    git config --global "alias.st" status
    git config --global "alias.br" branch
    git config --global "alias.co" checkout

    ln -s "$CONFIGS_DIR/global_gitignore" "$HOME_DIR/.global_gitignore"
    git config --global core.excludesfile "$HOME_DIR/.global_gitignore"

    echo "enter global git user: "
    read user
    echo "enter global git mail: "
    read mail

    git config --global user.name "$user"
    git config --global user.mail "$mail"
}

install_fix_display()
{
    path="$SCRIPTS_DIR/fix_display.sh"
    echo "@reboot bash $path 3840x2160 2>&1 >> $HOME_DIR/fix_display.log" >> "/var/spool/cron/crontabs/$USER"
    chown "$USER:crontab" "/var/spool/cron/crontabs/$USER"
}

install_rc()
{
    bashrc="$SCRIPTS_DIR/bashrc"
    vimrc="$SCRIPTS_DIR/vimrc"
    pythonrc="$SCRIPTS_DIR/pythonrc"

    ln -s "$bashrc" "$HOME_DIR/.bashrc"
    ln -s "$vimrc" "$HOME_DIR/.vimrc"
    ln -s "$pythonrc" "$HOME_DIR/.pythonrc"
}

confirm "install rc files?" "y" install_rc
confirm "install git?" "n" install_git
confirm "config git?" "n" config_git
confirm "install fix display?" "y" install_fix_display
