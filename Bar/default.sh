#!/bin/sh

#  default.sh
#
#  Created by Pavlo Denysiuk on 4/20/16.
#  Copyright © 2016 Pavlo Denysiuk. All rights reserved.

# Available commands for sending to menubar_fifo:
# text - just updates text in status bar with text.
# Example:
# date > menubar_fifo
#
# -----------------------------------------------------------------------------
#
# notify - creates a system notifications with text.
# Arguments:
#   informativeText - (Optional) Text displayed under main text. Usually an
#                     explanation of the notification.
#
#   makeSound       - (Optional) Boolean whether to play a sound with notification.
#                     Possible values: true, YES, 1.
# Example: echo "notify:CPU temperature is critical" > menubar_fifo
#
# -----------------------------------------------------------------------------
#
# icon - sets an icon in status bar from png image in path.
#
# Example: echo -e "icon:~/Documents/icon.png\twidth:16\theight:16" > menubar_fifo
#
# -----------------------------------------------------------------------------
#
# ask:question -- shows window with question and an edit field for user input.
#                 User input is then sent to user_input_fifo. "\tCANCEL\t" if cancelled.
# Example:
# echo "ask:Please log in" > menubar_fifo
# login=`cat user_input_fifo`
# echo "Hi, $login"
#

while true; do
    top -l 1 | head -n 7 | tail -n 1 | awk {' print "Memory used:", $2 ". Free:", $6 '} > menubar_fifo
    sleep 30
done
