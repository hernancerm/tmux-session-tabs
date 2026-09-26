# Recorded by `record.sh`, which makes the folders typed below. See https://github.com/charmbracelet/vhs.

Output demo.mp4

Set Shell zsh
Set Theme "GitHub Dark"
Set FontSize 20
Set Width 1200
Set Height 600
Set Padding 10
Set Margin 40
Set MarginFill "#2f5f3a"
Set WindowBar Colorful
Set WindowBarSize 50
Set BorderRadius 10
Set TypingSpeed 60ms

# Start tmux off camera. `-L` gives the demo its own server, so the user's sessions stay out.
Hide
Type "tmux -L tabs-demo -f tmux.conf new-session -c ~"
Enter
Sleep 2s
Show

Sleep 1s

# One session per project.
Type "cd ~/tmux-tabs-demo/api"
Enter
Sleep 1.5s

Ctrl+B
Type "t"
Sleep 0.8s
Type "cd ~/tmux-tabs-demo/website"
Enter
Sleep 1.5s

Ctrl+B
Type "t"
Sleep 0.8s
Type "cd ~/tmux-tabs-demo/notes"
Enter
Sleep 1.5s

# Walk left to the first tab, then right back to the last. Each step waits out `repeat-time`
# (500ms), else the next `Ctrl+B` lands in the repeat and goes to the shell.
Ctrl+B
Type "("
Sleep 1.2s
Ctrl+B
Type "("
Sleep 1.2s
Ctrl+B
Type ")"
Sleep 1.2s
Ctrl+B
Type ")"
Sleep 1.5s

# Move `notes` to the front, then one step back.
Ctrl+B
Left
Sleep 1.2s
Ctrl+B
Left
Sleep 1.5s
Ctrl+B
Right
Sleep 1.5s

# Kill `notes`. The client moves to another session instead of leaving tmux.
Ctrl+B
Type "w"
Sleep 1.2s
Type "y"
Sleep 1.5s

# A second window in `website`, with tmux's own key.
Ctrl+B
Type "c"

Sleep 3s
