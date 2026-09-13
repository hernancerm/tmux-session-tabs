# tmux-session-tabs

Display tmux sessions as tabs in the status line.

Target audience: People who use tmux locally and want to see sessions at a glance.

## Problem

I like using the tabs and split wins provided by terminal emulators themselves. However, I have two
problems with this multi-term/splits approach that motivate this plugin, tmux-session-tabs:

1. Terminal emulators can be "portable", but none I've come across is portable enough.
   - By "portable" I mean that the same multi-term/splits setup, including keybinds and features,
     works across OSs, has ok performance, and is reasonably available in most working environments.
     In this sense, I've found tmux to be more portable than any single terminal emulator.
2. Terminal emulators do not allow to mix split wins and fullscreen wins in the same tab scope.
   - Let's say I'm working on a web project. In my head, a tab holds a project, so the tab holds
     my editor, and perhaps a split win. I then want to start the server. I want the win for that to
     be scoped to the same project, so to the same tab. The terminals I've used cannot represent
     this structure, and even if one can, it still may have the first problem. tmux can represent
     this with sessions as "tabs".

## Solution

Display tmux sessions as tabs in the status line. The sessions _feel_ like tabs:

- The tabs can be manually ordered.
- Closing a session does not detach the client (`set-option -g detach-on-destroy off`).
- Tabs display the abbreviated cwd, and tabs may be manually labeled overriding the cwd auto-label.

tmux itself solves problem number 1, and this plugin solves problem number 2.

## Features

- Display tmux sessions as tabs in the status line.
- Expose options to set key binds for plugin actions, e.g., re-order tabs.
- In the status line, each session is auto-labeled with the abbreviated cwd (the "project name").
- Optionally, sessions can be manually labeled. This does `rename-session` and reflects it in the
  status line.
- Optionally, add arbitrary text on the right edge of the status line.
- Gracefully handle overflow with `<`/`>` markers in the status line.
- Support mouse to focus or close session or win.
- Partially support multiple clients.
- Closing sessions does not detach the client.
- Configure the status line colors.
- Status line survives a config reload.

## Limitations

- Multiple clients.
  - When 2 clients are in the same session, the width of the smallest client is used to draw the
    status line in both clients, so the larger client "shrinks". tmux does not support client-side
    options, so each status line is scoped to each session instead of each client.
- Themes compatibility.
  - Catpuccin and other themes do not play well with this plugin, because both use
     `status-format[0]`.
- Session names.
  - Sessions are automatically named with an integer, so `tmux ls` and any other command that
    exposes the real session names outputs meaningless names. This limitation does not apply when
    [labelling sessions](#labels), it only applies when using the default cwd auto-labeling.

## Requirements

- bash >=3.2 (macOS out-of-the-box satisfies this.)
- tmux >=3.2

## Installation

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'tmux-session-tabs'
```

Or, manually:

```tmux
run-shell ~/path/to/tmux-session-tabs/session-tabs.tmux
```

Finally, set [keybinds](#keybinds).

## Keybinds


**The plugin binds no key on its own.**

Set these options to the keys you want before the plugin loads:

```text
set -g @session-new-key "t"             # Create session.
set -g @session-kill-key "w"            # Kill the current session, with confirmation.
set -g @session-last-key "Tab"          # Focus the last active session.
set -g @session-label-key "L"           # Label the current session.
set -g @session-prev-key "Up"           # Select left session.
set -g @session-next-key "Down"         # Select right session.
set -g @session-move-left-key "Left"    # Move current session left.
set -g @session-move-right-key "Right"  # Move current session right.
```

Repeatable without prefix (`-r` behavior):

- `@session-prev-key`
- `@session-next-key`
- `@session-move-left-key`
- `@session-move-right-key`

Non-configurable mouse key binds for the status line:

| Mouse | Action |
| --- | --- |
| Middle click | Kill the clicked session or win, with confirmation. |
| Left click | Focus the clicked session or window. |

## Style

To change the status line colors, set these options:

| Option | Default | What it does |
| --- | --- | --- |
| `@session-style-sel` | `bg=#4689e0,fg=#ffffff` | Styles the current session. |
| `@session-style-fill` | `bg=#f0f6fe,fg=#6e7781` | Styles every non-current session. |
| `@session-show-window-index` | `off` | `on` prefixes each window with its index, as `0:zsh` |
| `@session-right` | empty | Text drawn on the right edge. |
| `@session-right-length` | `0` | Columns for right-edge text. |

## Right-edge text

The tabs are left-aligned. On the right edge, text can be displayed via `@session-right`. It holds a
format. Example:

```tmux
set -g @session-right " %H:%M "
set -g @session-right-length 7
```

The option `@session-right-length` is the columns reserved for the right-edge text.

Since the right-edge text is a format, it can be styled. Example:

```tmux
set -g @session-right '#[fg=#ffffff,bg=#d13212,bold] WARN #[fg=#000000,bg=#f5d90a,nobold] 3 '
set -g @session-right-length 9
```

The gap between the tabs and the right-edge text is painted with the background of
`@session-style-fill`, so no theme setup is needed. The plugin does not set `status-style`: that
option belongs to the config or a theme.

One consequence: in the right-edge text, `#[default]` returns to `status-style`, not to
`@session-style-fill`. Set an explicit style instead of relying on `#[default]`.

## Published options

The plugin publishes two read-only options, for a config that wants the same text elsewhere. Both
hold a format, so reading one takes `#{E:...}` to expand it a second time:

```tmux
set -g set-titles-string "#{E:@session-dir}"
```

TODO: Both of these opts needed?

| Option | Holds |
| --- | --- |
| `@session-dir` | The current directory, with `$HOME` as `~` |
| `@session-label` | What the tab draws: the label, or the shortened directory |

A style cannot be written inside a `#{?...}` format instead: the comma in `bg=...,fg=...` would
read as the separator between the branches of the conditional. That is why the script picks one of
the two and puts it ahead of each loop.

## Labels

A session with no label shows its abbreviated cwd, e.g. `~/dev/repos/foo` as `~/d…/r…/foo`. However,
the actual session's name is a meaningless integer. So these do not show the same text as the status
line:

- `attach -t`
- `switch-client -t`
- `choose-tree`

`@session-label-key` sets a label and renames the session to match, making both parts agree. Use
this only when wanting an explicit label for a session. See [Keybinds](#keybinds).

## State

The status line survives a config reload by stiring its state in tmux options:

| Option | Scope | Meaning |
| --- | --- | --- |
| `@order` | session | Position on the status line, kept a gapless `1..n`. |
| `@label` | session | The name drawn on the line, empty for the shortened cwd. |
| `@sessions-viewport-start` | session | Index of the first session shown, the scroll position. |
| `@sessions-hidden-left` / `-right` | session | Counts drawn in the `<` and `>` markers. |
