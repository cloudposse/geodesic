# Demo of Geodesic

Output docs/demo.gif

Set Theme "Monokai Vivid"

#Set FontFamily "FiraCode Nerd Font"
Set FontFamily "Hack Nerd Font"
Set FontSize 14

Set TypingSpeed 40ms

Set Framerate 30

Set WindowBar Colorful

Set CursorBlink true

Set BorderRadius 8

Set Margin 20
Set MarginFill "#674EFF"

Set Padding 12

Set Width 1200
Set Height 600

Set PlaybackSpeed 1

Set Shell bash

Type "# After having run `make all`, simply run `make run` (or `geodesic`) to enter the interactive shell" Enter
Sleep 500ms

Type "geodesic" Enter

Sleep 4s

Type "#  Open Tofu is pre-installed:" Enter
Type "demo-tofu-version" Enter
Sleep 3s

Type "#  Geodesic ships with common commands like `jq`" Enter
Sleep 1500ms

Type "jq" Enter
Sleep 3s

Type "#  ...and `kubectl`" Enter
Sleep 1500ms

Type "kubectl" Enter@3s

Type "#  ...and many other added packages" Enter
Type "demo-list-packages" Enter
Sleep 20s

Type "#  That's all folks!" Enter
Sleep 2s

Type "exit" Enter
Sleep 3s

