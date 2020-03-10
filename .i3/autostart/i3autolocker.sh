#!/bin/zsh

# Only exported variables can be used within the timer's command.
# export PRIMARY_DISPLAY="$(xrandr | awk '/ primary/{print $1}')"

# Get current brightness level
DIS_BRIGHTNESS="($xbacklight -get)"

# Run xidlehook
# xidlehook \
#   # `# Don't lock when there's a fullscreen application` \
#   # --not-when-fullscreen \
#   `# Don't lock when there's audio playing` \
#   --not-when-audio \
#   `# Dim the screen after 10 minutes, undim if user becomes active` \
#   --timer 60 \
#     'xbacklight -set 1%' \
#     'xbacklight -set 50%' \
#     # 'xrandr --output "$PRIMARY_DISPLAY" --brightness .1' \
#     # 'xrandr --output "$PRIMARY_DISPLAY" --brightness 1' \
#   `# Undim & lock after 10 more seconds` \
#   --timer 10 \
#     'xbacklight -set 50%; i3lock -i ~/Pictures/wallpapers/OPM/56055_one_punch_man.jpg' \
#     # 'xrandr --output "$PRIMARY_DISPLAY" --brightness 1; i3lock -i /home/tom/Pictures/wallpapers/OPM/56055_one_punch_man.png' \
#     '' \
#   `# Finally, suspend 5 minutes after it locks` \
#   --timer 3600 \
#     'systemctl suspend' \
#     ''
xidlehook --not-when-audio --timer 60 'xbacklight -set 1' "xbacklight -set $DIS_BRIGHTNESS" --timer 10 'xbacklight -set $DIS_BRIGHTNESS; i3lock -i /home/tom/Pictures/wallpapers/OPM/56055_one_punch_man.png' '' --timer 300 'systemctl suspend' ''
