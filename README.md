#### Description of supported commands
##### Text
Default command. Called when it's an unrecognized command or no command at all.

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
Shows a window with a prompt and edit field. User input is then sent to user_input_fifo. "\tCANCEL\t" if cancelled.

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
