# Demo

The video at the top of the main README is recorded from `demo.tape` with
[VHS](https://github.com/charmbracelet/vhs).

## Record

Install VHS once (it pulls in `ttyd` and `ffmpeg`):

```sh
brew install vhs
```

Then, from anywhere:

```sh
demo/record.sh
```

It writes `demo/demo.mp4` in about 30s. The mp4 is git-ignored.

`record.sh` makes `~/tmux-tabs-demo/{api,website,notes}` for the demo to `cd` into, and deletes it
when done. If `~/tmux-tabs-demo` already exists, it stops without touching it.

## Publish

GitHub only plays a README video uploaded through its website, not an mp4 in the repo:

1. On github.com, edit `README.md` and drag `demo/demo.mp4` into the editor.
2. GitHub replaces it with a `https://github.com/user-attachments/assets/...` URL.
3. Put that URL on its own line, below the one-line description, replacing the old one.

## Edit

- `demo.tape`: the steps. See the [VHS docs](https://github.com/charmbracelet/vhs#vhs-command-reference).
- `tmux.conf`: the plugin's keys used in the tape. It is the only tmux config loaded.
- `zdotdir/.zshrc`: the prompt. It replaces the user's zsh config.
- `record.sh`: the project folders. Renaming one means updating its `cd` line in `demo.tape`.

Keys that repeat (`prev`, `next`, `move`) need a `Sleep` over 500ms after them (tmux's
`repeat-time`), else the next `Ctrl+B` goes to the shell.
