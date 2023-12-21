# Demo of Geodesic

Output docs/gifs/demo.gif
#Output docs/mp4/demo.mp4
#Output docs/webm/demo.webm

#Set Theme "Builtin Solarized Dark"
Set Theme "Monokai Vivid"

Set FontFamily "FiraCode Nerd Font"
Set FontSize 14

Set TypingSpeed 40ms

Set Framerate 30

Set WindowBar Colorful

Set CursorBlink true

Set BorderRadius 10

Set Padding 12

Set Width 1200
Set Height 600

Set PlaybackSpeed 0.50

Set Shell bash

# Test glyph rendering
Type "export" Enter
Sleep 3
Type "echo '⧉  ✗ ⨠ '"
Enter
Sleep 5s

Sleep 1.5s

Type "# After having run `make all`, simply run `geodesic` to enter the interactive shell" Enter
Sleep 2

Type "geodesic"
Enter

Sleep 5s

Type "# It ships with common commands like `terraform`" Enter
Sleep 2

Type "terraform -help"
Enter

Sleep 3s

Type "# ...and the `aws` CLI =)" Enter
Sleep 2

Type "aws help"
Enter

Sleep 3s

Type "q"
Sleep 1s

Type "# That's all folks!" Enter
Sleep 5s

Type "exit"
Enter
#Ctrl+D

