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
Hide
Type@1ms "stty -echo" Enter
Type@1ms "printf 'Tofu Version as of when we recorded this demo:\n'; printf '    %s\n' $(tofu version | sed 's/ / /g') && stty echo"
Show
Enter
Sleep 3s

Type "#  Geodesic ships with common commands like `jq`" Enter
Sleep 1500ms

Type "jq" Enter
Sleep 3s

Type "#  ...and `kubectl`" Enter
Sleep 1500ms

Type "kubectl" Enter@3s

Type "#  ...and many other added packages" Enter
Hide
Type@1ms "stty -echo" Enter
Show
Type@1ms "printf '\n\nPackages installed by Geodesic:\n\n'; apt list --manual-installed=true 2>/dev/null | tail -n +2 | cut -f1 -d/ | pr -4 -t -a -w 100 && stty echo" Enter
Sleep 20s

Type "#  That's all folks!" Enter
Sleep 2s

Type "exit" Enter
Sleep 3s

