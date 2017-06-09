run_sudo()
{
    echo "qwerty" | sudo -S $@
}

# display resolution shit.
run_sudo cvt 3840 2160 60
run_sudo xrandr --newmode 3840x2160  712.75  3840 4160 4576 5312  2160 2163 2168 2237 -hsync +vsync
run_sudo xrandr --addmode Virtual1 3840x2160
