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

save_dir()
{
    local old_pwd="$(pwd)"
    func="$1"
    shift
    eval "$func" $@
    cd "$old_pwd"
}

confirm()
{
    message="$1"
    shift
    default="$1"
    shift
    func="$1"
    shift
    if [[ "$default" == y ]]
    then
        do_it=1
        default="[Yn]"
    elif [[ "$default" == n ]]
    then
        do_it=0
        default="[yN]"
    else
        do_it=0
        default=
    fi

    echo -n "$message $default: "
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
        eval "$func" $@
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

    ln -sf "$CONFIGS_DIR/git-completion.bash" "$HOME_DIR/git.autocompletion"
    ln -sf "$CONFIGS_DIR/global_gitignore" "$HOME_DIR/.global_gitignore"
    git config --global core.excludesfile "$HOME_DIR/.global_gitignore"

    echo "enter global git user: "
    read user
    echo "enter global git mail: "
    read mail

    git config --global user.name "$user"
    git config --global user.email "$mail"
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

    ln -sf "$bashrc" "$HOME_DIR/.bashrc"
    ln -sf "$vimrc" "$HOME_DIR/.vimrc"
    ln -sf "$pythonrc" "$HOME_DIR/.pythonrc"
}

install_packages()
{
    for repo in $(cat "$CONFIGS_DIR/repositories.txt")
    do
        echo "adding $repo"
        add-apt-repository "$repo"
    done
    apt-get update
    for package in $(cat "$CONFIGS_DIR/install_packages.txt")
    do
        echo "installing $package"
        fast_install "$package"
    done
}

clone_project()
{
    git clone "$1"
    chown -R "$USER:$USER" $(echo $(basename "$1") | cut -f1 -d'.')
    if [ ! -z "$2" ]
    then
        save_dir "$2"
    fi
}

clone_projects()
{
    cd "$HOME/projects"
    declare -a repos
    readarray -t repos < "$CONFIGS_DIR/git_repositories.txt"
    for repo in "${repos[@]}"
    do
        post_script=$(echo "$repo" | cut -s -f2 -d" ")
        repo=$(echo "$repo" | cut -f1 -d" ")
        confirm "> clone $repo?" "n" clone_project "$repo" "$post_script"
    done
}

tmux_config()
{
    cd 
    ln -sf projects/.tmux/.tmux.conf
    cp projects/.tmux/.tmux.conf.local .
}

commacd_config()
{
    curl -sL https://github.com/shyiko/commacd/raw/v0.4.0/commacd.bash -o commacd/.commacd.bash
}

confirm "install rc files?" "n" install_rc
confirm "install git?" "n" install_git
confirm "config git?" "n" config_git
confirm "install fix display?" "n" install_fix_display
confirm "install packages?" "n" install_packages
confirm "clone projects?" "n" save_dir clone_projects

