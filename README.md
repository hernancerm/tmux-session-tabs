# tmux-session-tabs

Display tmux sessions as tabs in the status line.

## Problem

Sessions in tmux do not feel like tabs, I want them to feel like tabs.

## Solution

Display tmux sessions as "tabs" in the status line.

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
  - Catppuccin and other themes do not play well with this plugin, because both use
    `status-format[0]`. The theme's colors can still be reused, see [Style](#style).
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
set -g @plugin 'hernancerm/tmux-session-tabs'
```

Or, manually:

```tmux
run-shell ~/path/to/tmux-session-tabs/session-tabs.tmux
```

Finally, do as described in [Keybinds](#keybinds).

## Keybinds

**The plugin binds no key on its own.**

Set these options to the keys you want before the plugin loads:

```text
set -g @session-new-key "t"             # Create session.
set -g @session-kill-key "w"            # Kill the current session, with confirmation.
set -g @session-last-key "Tab"          # Focus the last active session.
set -g @session-label-key '\;'          # Label the current session.
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

## What the plugin sets

These global options are written on load, on top of anything the config set:

| Option | Value | Why |
| --- | --- | --- |
| `status-format[0]` | the tabs | The status line itself. |
| `status-interval` | `1` | The cwd label only updates on redraw. |
| `detach-on-destroy` | `off` | Killing the current session moves the client instead of ending tmux. |

Hooks on `client-attached`, `client-session-changed`, `client-resized`, `session-created`,
`session-closed`, `window-linked` and `window-unlinked` are set at index `50`, so hooks the config
sets on those events (at other indexes) are kept.

## Style

To change the status line colors, set these options:

| Option | Default | What it does |
| --- | --- | --- |
| `@session-style-sel` | `bg=#4689e0,fg=#ffffff` | Styles the current session. |
| `@session-style-fill` | `bg=#f0f6fe,fg=#6e7781` | Styles every non-current session. |
| `@session-right-text` | empty | Text drawn on the right edge of the status line. |
| `@session-right-text-width` | `0` | Columns reserved for `@session-right-text`. |
| `@session-show-win-index` | `off` | `on` prefixes each win with its index, as `0:zsh`. |

The styles hold a format, so a theme's colors can be reused, e.g. with Catppuccin:
`set -g @session-style-fill "bg=#{@thm_surface_0},fg=#{@thm_subtext_0}"`.

## Right-edge text

The tabs are left-aligned. On the right edge, text can be displayed via `@session-right-text`. It
holds a format. Example:

```tmux
set -g @session-right-text " %H:%M "
set -g @session-right-text-width 7
```

The option `@session-right-text-width` is the columns reserved for the right-edge text.

Since the right-edge text is a format, it can be styled. Example:

```tmux
set -g @session-right-text '#[fg=#ffffff,bg=#d13212,bold] WARN #[fg=#000000,bg=#f5d90a,nobold]'
set -g @session-right-text-width 6
```

A conditional, `#{?...}`, in the right-edge text cannot hold a comma: `#{?...}` reads it as the
separator between its branches, so `bg=...,fg=...` is cut in half. Write one `#[...]` per attribute.
Example:

```tmux
# Broken:
set -g @session-right-text '#{?client_prefix,#[bg=#d13212,fg=#ffffff] PFX ,}'

# Works:
set -g @session-right-text '#{?client_prefix,#[bg=#d13212]#[fg=#ffffff] PFX ,}'
```

The gap between the tabs and the right-edge text is painted with the background of
`@session-style-fill`, so no theme setup is needed. The plugin does not set `status-style`: that
option belongs to the config or a theme.

One consequence: in the right-edge text, `#[default]` returns to `status-style`, not to
`@session-style-fill`. Set an explicit style instead of relying on `#[default]`.

## Introspection

The plugin publishes two read-only options, for a config that wants the same text elsewhere:


| Option | Holds |
| --- | --- |
| `@session-dir` | The cwd, with `$HOME` as `~`. |
| `@session-label` | What the tab displays: the label or the abbreviated cwd. |

Both hold a format, so reading one takes `#{E:...}` to expand it. Example:

```tmux
set -g set-titles-string "#{E:@session-dir}"
```

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

The status line survives a config reload by storing its state in tmux options:

| Option | Scope | Meaning |
| --- | --- | --- |
| `@order` | session | Position on the status line, kept a gapless `1..n`. |
| `@label` | session | The name drawn on the line, empty for the shortened cwd. |
| `@sessions-viewport-start` | session | Index of the first session shown, the scroll position. |
| `@sessions-hidden-left` / `-right` | session | Counts drawn in the `<` and `>` markers. |
