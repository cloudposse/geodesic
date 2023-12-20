# Demo of Geodesic

Output docs/gifs/demo.gif
Output docs/mp4/demo.mp4
Output docs/webm/demo.webm

Set Theme "Builtin Solarized Dark"

Set FontFamily "Fira Code"
Set FontSize 12

Set WindowBar Colorful

Set CursorBlink true

Set BorderRadius 10

Set Padding 5

Set Width 1200
Set Height 600

Set PlaybackSpeed 0.50

Set Shell bash

Type "make demo-deps"
Enter
Sleep 10s

# Test glyph rendering
Type "echo ' ⧉  geodesic'"
Enter
Sleep 1s
Type "echo ' ✗ . [none] (HOST) geodesic ⨠ "
Enter
Sleep 5s

Sleep 1.5s
Type "geodesic"
Enter

Sleep 5s

Type "terraform -help"
Enter

Sleep 3s

Type "aws help"
Enter

Sleep 3s

Type "q"
Sleep 5s

Type "quit"
Enter

Type "exit"
Enter
Ctrl+D

