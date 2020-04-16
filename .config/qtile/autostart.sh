 #! /bin/bash 
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
nitrogen --restore &
picom -b --config /home/tom/.config/picom/picom.conf &
gnome-power-manager &
nm-applet &
pamac-tray &
clipit &
/home/tom/autostart/i3autolocker.sh &
ff-theme-util &
fix_xcursor &
/usr/bin/telegram-desktop &
/usr/bin/syncthing --no-browser  &
nextcloud  & 
redshift-gtk  &
libinput-gestures-setup start &
/home/tom/.i3/autostart/launch-whatsdesk.sh
/usr/bin/synclient CoastingSpeed=30 &
/home/tom/.config/polybar/launch.sh &