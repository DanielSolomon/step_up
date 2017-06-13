#set -x

run_sudo()
{
    echo "qwerty" | sudo -S $@
}

mode=1
while [[ ! -z $1 ]]
do
    echo "$1"
    w=$(echo "$1" | cut -d'x' -f1)
    h=$(echo "$1" | cut -d'x' -f2)
    # display resolution shit.
    run_sudo cvt $w $h 60
    run_sudo xrandr --newmode $1  712.75  $w 4160 4576 5312  $h 2163 2168 2237 -hsync +vsync
    run_sudo xrandr --addmode Virtual$mode $1
    shift
    mode=$((mode + 1))
done
