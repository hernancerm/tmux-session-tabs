# tmux-session-tabs

A tmux status line where sessions are tabs: ordered by hand, labelled, clickable, and scrolled into
view when they no longer fit the terminal width.

```
 <1   ~/d…/r…/nvim(1:zsh* 2:make)    api(1:server* 2:logs 3:zsh)    ~/notes(1:zsh*)   2>
```

tmux walks sessions in name order (`#{S:}`) and offers no way to reorder them, so the line is not
written as a static format. `tmux-status-viewport` measures each session, decides which ones fit,
and writes `status-format[0]` with one single-session loop per tab, in `@order` order.

It takes over `status-format[0]`, so it does not combine with other status line themes.

## Install

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'tmux-session-tabs'
```

Manually:

```tmux
run-shell ~/path/to/tmux-session-tabs/session-tabs.tmux
```

Requires `zsh` on `PATH` and tmux 3.2 or newer (`status-format`, `#{S:}`, `list-sessions -f`).

## Options

Set these before the plugin loads. They are only defaulted, so yours win.

| Option | Default | What it styles |
| --- | --- | --- |
| `@session-style` | `bg=#f0f6fe,fg=#6e7781` | The line, and every session that is not current |
| `@session-style-current` | `bg=#4689e0,fg=#ffffff` | The current session |

A style cannot be written inside a `#{?...}` format instead: the comma in `bg=...,fg=...` would
read as the separator between the branches of the conditional. That is why the script picks one of
the two and puts it ahead of each loop.

## Keys

| Key | Action |
| --- | --- |
| `t` | Create a session (overrides "Display a large clock") |
| `;` | Label the current session (overrides "Select the previously active pane") |
| `w` | Kill the current session (overrides "Choose a window from a list") |
| `Tab` | Select the last active session |
| `Up` / `Down` | Select the previous / next session |
| `Left` / `Right` | Move the current session left / right on the line |
| left click | Focus the clicked session or window |
| middle click | Kill the clicked session or window, after a confirmation |

The plugin also sets `detach-on-destroy off`: killing the session the client sits on would otherwise
detach it and end tmux, instead of sending the client to the next session.

These bindings are not opt-in yet, and several of them override tmux defaults. Comment them out in
`session-tabs.tmux` if they clash.

## Labels

A session with no label shows its current directory, shortened one char per parent
(`~/dev/repos/foo` reads `~/d…/r…/foo`). `;` sets a label, and renames the session to match, so
`attach -t`, `switch-client -t` and `choose-tree` use the same word you see on the line. An empty
label clears both.

## Known issues

- **Multiple clients on one server.** The scripts size and highlight the line for the first client
  in `list-clients`. With two terminals attached to the same server, the line follows the wrong one.

## State

The plugin keeps its bookkeeping in tmux options, so it survives a config reload:

| Option | Scope | Meaning |
| --- | --- | --- |
| `@order` | session | Position on the line, kept a gapless `1..n` |
| `@label` | session | The name drawn on the line, empty for the shortened cwd |
| `@sessions-viewport-start` | global | Index of the first session shown, the scroll position |
| `@sessions-hidden-left` / `-right` | global | Counts drawn in the `<` and `>` markers |
