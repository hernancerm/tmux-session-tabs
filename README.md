# tmux-session-tabs

A tmux status line where sessions are tabs: ordered by hand, labelled, clickable, and scrolled into
view when they no longer fit the terminal width.

```
 <1   ~/d…/r…/nvim(1:zsh* 2:make)    api(1:server* 2:logs 3:zsh)    ~/notes(1:zsh*)   2>
```

tmux walks sessions in name order (`#{S:}`) and offers no way to reorder them, so the line is not
written as a static format. `tmux-status-viewport` measures each session, decides which ones fit,
and writes `status-format[0]` with one single-session loop per tab, in `@order` order. It writes one
line per attached session, so each client gets its own width, scroll position and highlight.

It takes over `status-format[0]`, the whole top row, so `status-left`, `status-right` and
`window-status-format` are never drawn. Those are what a theme plugin sets, so it does not combine
with one. `@session-right` below covers the case those themes are usually wanted for.

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'tmux-session-tabs'
```

Manually:

```tmux
run-shell ~/path/to/tmux-session-tabs/session-tabs.tmux
```

Requires `bash` 3.2 or newer, the version macOS ships, and tmux 3.2 or newer (`status-format`,
`#{S:}`, `list-sessions -f`).

## Options

Set these before the plugin loads. They are only defaulted, so yours win.

| Option | Default | What it does |
| --- | --- | --- |
| `@session-style-fill` | `bg=#f0f6fe,fg=#6e7781` | Styles every session that is not current, and the `<` / `>` markers |
| `@session-style-sel` | `bg=#4689e0,fg=#ffffff` | Styles the current session |
| `@session-show-window-index` | `off` | `on` prefixes each window with its index, as `0:nvim` |
| `@session-right` | empty | Text drawn on the right edge. A format, expanded on every redraw |
| `@session-right-length` | `0` | Columns the tabs leave free for it |

### Right-edge text

`@session-right` holds a format, so what it draws stays live:

```tmux
set -g @session-right " %H:%M "
set -g @session-right-length 7
```

The length is declared rather than measured: measuring means expanding the text on every rebuild, so
a `#()` in it would run that much more often. Set it too low and the tabs run under the text, too
high and you lose tab space.

The text carries its own styles, and a style takes no columns, so the length counts only the visible
characters. Quote it with `'...'`, which stores the `#[...]` as written instead of expanding it at
config-parse time:

```tmux
set -g @session-right '#[fg=#ffffff,bg=#d13212,bold] WARN #[fg=#000000,bg=#f5d90a,nobold] 3 '
set -g @session-right-length 9
```

`#[default]` in there returns to `status-style`, not to `@session-style-fill`. The plugin leaves
`status-style` alone, so that is tmux's own green until the config sets it. Setting it also colours
the gap between the tabs and the text:

```tmux
set -g status-style "bg=#f0f6fe,fg=#6e7781"
```

## Published options

The plugin publishes two read-only options, for a config that wants the same text elsewhere. Both
hold a format, so reading one takes `#{E:...}` to expand it a second time:

```tmux
set -g set-titles-string "#{E:@session-dir}"
```

| Option | Holds |
| --- | --- |
| `@session-dir` | The current directory, with `$HOME` as `~` |
| `@session-label` | What the tab draws: the label, or the shortened directory |

A style cannot be written inside a `#{?...}` format instead: the comma in `bg=...,fg=...` would
read as the separator between the branches of the conditional. That is why the script picks one of
the two and puts it ahead of each loop.

## Keys

**The plugin binds no key on its own: every key worth binding here already means something in tmux,
so the choice is left to your config. Set these before the plugin loads. An unset option binds
nothing.**

| Option | Action |
| --- | --- |
| `@session-new-key` | Create a session |
| `@session-kill-key` | Kill the current session, after a confirmation |
| `@session-last-key` | Select the last active session |
| `@session-label-key` | Label the current session |
| `@session-prev-key` / `@session-next-key` | Select the previous / next session on the line, wrapping at the ends |
| `@session-move-left-key` / `@session-move-right-key` | Move the current session left / right on the line, stopping at the ends |

The four that walk the line are bound with `-r`, so they repeat without the prefix.

A suggestion, the set this was written with. Each one takes over a tmux default, named on the right:

```tmux
set -g @session-new-key "t"                # Display a large clock
set -g @session-kill-key "w"               # Choose a window from a list
set -g @session-last-key "Tab"             # Popup pane, where tmux has one
set -g @session-label-key "L"              # Switch to the last client
set -g @session-prev-key "Up"              # Select the pane above
set -g @session-next-key "Down"            # Select the pane below
set -g @session-move-left-key "Left"       # Select the pane to the left
set -g @session-move-right-key "Right"     # Select the pane to the right
```

The mouse is not configurable: these are bound to the status line, not to a key you could want back.

| Mouse | Action |
| --- | --- |
| left click | Focus the clicked session or window |
| middle click | Kill the clicked session or window, after a confirmation |

The plugin also sets `detach-on-destroy off`: killing the session the client sits on would otherwise
detach it and end tmux, instead of sending the client to the next session.

## Labels

A session with no label shows its current directory, shortened one char per parent
(`~/dev/repos/foo` reads `~/d…/r…/foo`). `L` sets a label, and renames the session to match, so
`attach -t`, `switch-client -t` and `choose-tree` use the same word you see on the line. An empty
label clears both.

Selection follows the line, not tmux's own session order: `switch-client -p/-n` walks sessions by
name, so a session named `0` by `C-b t` sits before every labelled one, and the two orders disagree
as soon as one exists. `tmux-select-session` steps through `@order` instead.

## Known issues

- **Two clients on one session.** `status-format` is a session option and tmux has no per-client
  one, so clients sharing a session share a line. The narrower one decides how much fits, as tmux
  does when it sizes a shared session. Clients on different sessions are unaffected.

## State

The plugin keeps its bookkeeping in tmux options, so it survives a config reload:

| Option | Scope | Meaning |
| --- | --- | --- |
| `@order` | session | Position on the line, kept a gapless `1..n` |
| `@label` | session | The name drawn on the line, empty for the shortened cwd |
| `@sessions-viewport-start` | session | Index of the first session shown, the scroll position |
| `@sessions-hidden-left` / `-right` | session | Counts drawn in the `<` and `>` markers |

The global `status-format[0]`, and global `0` for both counters, are the fallback a session draws
until a client attaches to it and the `client-attached` hook writes it its own line.
