#### Description of supported commands
Parameters are passed using '\t' in the command text.  
If you're using `echo`, specify `-e` argument so it handles escape characters.  
For example:  
```
echo -e "notify:Hello\tinformativeText:This is a text" > menubar_fifo
```

##### Text
Default command.  
Called when it's an unrecognized command or no command at all.

Example:
```
date > menubar_fifo
```

##### Notify
`notify` command.  
Creates a system notification.

- Parameters:
  - informativeText: (Optional) Text displayed under main text. Usually an explanation of the notification.
  - makeSound: (Optional) Boolean whether to play a sound with notification. Possible values: `true, YES, 1`.

Example:
```
echo "notify:CPU temperature is critical" > menubar_fifo
```

##### Ask
`ask` command.  
Shows a window with a prompt and edit field. User input is then sent to user_input_fifo. ``"\tCANCEL\t"`` if cancelled.

- Parameters:
  - informativeText: (Optional) Text displayed under main text. Usually an explanation of what is asked.
  - protected: (Optional) Boolean whether edit field is password field. Possible values: `true, YES, 1`.

Example:
```
echo "ask:Please log in" > menubar_fifo
login=`cat user_input_fifo`
echo "Hi, $login"
```

##### Icon
`icon` command.  
Sets an icon in system bar.

- Parameters:
  - width: (Optional) Desired image width.
  - height: (Optional) Desired image height.

Example:
```
echo -e "icon:icon.png\twidth:16\theight:16" > menubar_fifo
```

#### Custom menus
To create custom menu, click on your menu bar -> "Open scripts dir", Finder window will open.  
Create directory "menus" and place shell scripts inside it. Then restart the Bar application (see TODO: there will be a button/command/automatic, some way to rescan custom menus).  
Menu item will have the name of the shell file.

#### TODO
1. Restart script handler.
2. Rescan menus.
3. Examples with more sophisticated commands.
4. How to create menus.
