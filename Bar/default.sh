#!/bin/sh

#  default.sh
#
#  Created by Pavlo Denysiuk on 4/20/16.
#  Copyright © 2016 Pavlo Denysiuk. All rights reserved.

# Available commands for sending to menubar_fifo:
# text - just updates text in status bar with text. If text has newlines
#        first line is shows in status bar. Other lines are shown as menu item.
# Example: printf "First line\n`date`\nThird line" > menubar_fifo
#
# -----------------------------------------------------------------------------
#
# notify:text - creates a system notifications with text.
# Example: echo "notify:CPU temperature is critical" > menubar_fifo
#
# -----------------------------------------------------------------------------
#
# icon:path -- sets an icon in status bar from png image in path.
#              Preferable resolutions: 16x16, 24x24, 32x32,
# Example: echo "icon:~/Documents/icon.png" > menubar_fifo
#
# -----------------------------------------------------------------------------
#
# prompt:question -- shows window with question and an edit field
#                    for user input. User input is then sent to
#                    user_input_fifo
# Example:
# echo "prompt:Please log in" > menubar_fifo
# login=`cat user_input_fifo`
# echo "Hi, $login"
#
# -----------------------------------------------------------------------------
#
# menu:title\thandler:script -- adds menu item with title to menu which calls
#                               script when clicked. Script will block main thread.
# Example:
# echo -e "menu:Show my IP\thandler:show_ip.sh" > menubar_fifo
# Keep in mind that you need to use '-e' argument so echo interprets special chars.
# In show_ip.sh you can write a script that will do:
# echo "notify:`ifconfig en0 | grep 'inet ' | awk '{ print $2 }'`" > menubar_fifo
# This will show a notification with your ip.
#
# menu:\tclear: -- removes all menu items added by user.

while true; do
    top -l 1 | head -n 7 | tail -n 1 | awk {' print "Memory used:", $2 ". Free:", $6 '} > menubar_fifo
    sleep 30
done
