#!/usr/bin/env bash

## Entry point: sets the status line format, the hooks that rebuild it, and the key bindings that
## drive it. Written as a script rather than a `.conf` file because a config file expands `${...}`
## for the whole file before running any of its commands, which forces theme values to be set from
## an already-executed `source`. A script has no such ordering problem.

plugin="$(cd "$(dirname "$0")" && pwd -P)"
scripts="${plugin}/scripts"


# OPTIONS

# Styles are only defaulted, so a `.tmux.conf` that sets them before loading the plugin wins.
if [[ -z "$(tmux show-option -gqv @session-style)" ]]; then
  tmux set-option -g @session-style "bg=#f0f6fe,fg=#6e7781"
fi
if [[ -z "$(tmux show-option -gqv @session-style-current)" ]]; then
  tmux set-option -g @session-style-current "bg=#4689e0,fg=#ffffff"
fi
if [[ -z "$(tmux show-option -gqv @session-show-window-index)" ]]; then
  tmux set-option -g @session-show-window-index "off"
fi

style="$(tmux show-option -gqv @session-style)"


# STATUS LINE

tmux set-option -g status-style "${style}"

# Pane current path with `$HOME` substituted with `~`.
SESSION_DIR="#{s|^${HOME}|~|:pane_current_path}"
# Shorten every parent dir to its first char. Only names of 3+ chars shrink.
# Examples:
#   ~/dev/repos/foo  ->  ~/d…/r…/foo
#   ~/xy/abc/foo     ->  ~/xy/a…/foo
#   ~/x/abc/foo      ->  ~/x/a…/foo
SESSION_DIR_SHORT="#{s,([^/])[^/][^/]+/,\\1…/,:${SESSION_DIR}}"

# A session shows its label when it has one.
SESSION_LABEL="#{?@label,#{@label},${SESSION_DIR_SHORT}}"

# Published for a config that wants the same text elsewhere, e.g. `set-titles-string`. They hold a
# format, so reading them takes `#{E:@session-dir}` to expand it a second time.
tmux set-option -g @session-dir "${SESSION_DIR}"
tmux set-option -g @session-label "${SESSION_LABEL}"

# The index prefix is off by default: it costs 2+ chars per window, and the line overflows sooner.
# Turn it on to tell apart two windows that share a name.
WINDOW_INDEX=""
if [[ "$(tmux show-option -gqv @session-show-window-index)" == "on" ]]; then
  WINDOW_INDEX="#{window_index}:"
fi

WINDOW_LIST="#{W:#[range=user|#{session_id}:#{window_index}]\
${WINDOW_INDEX}#{window_name}#{window_flags}#[norange]#{?window_end_flag,,#,}}"

SESSION_ITEM="#[range=user|#{session_id}]  ${SESSION_LABEL}(#[norange]\
${WINDOW_LIST}#[range=user|#{session_id}])  #[norange]"

# Sessions outside the viewport are left out of the line, and counted on the edge they fell off.
HIDDEN_LEFT="#{?@sessions-hidden-left, <#{@sessions-hidden-left},}"
HIDDEN_RIGHT="#{?@sessions-hidden-right,#{@sessions-hidden-right}> ,}"

# `#{S:}` walks sessions sorted by name, so the line cannot order them on its own.
# `tmux-status-viewport` writes `status-format[0]`: it replaces the placeholder with one loop per
# session, each filtered to a single session id, which puts them in `@order` order. It measures a
# session by expanding the item too, to know how many fit.
tmux set-option -g @session-item "${SESSION_ITEM}"
tmux set-option -g @status-skeleton "#[align=left]#[${style}]${HIDDEN_LEFT}\
%%SESSIONS%%#[${style}]${HIDDEN_RIGHT}"

# The cwd label only updates on redraw, so keep this low.
tmux set-option -g status-interval 1


# HOOKS

# The status line is rebuilt by `tmux-status-viewport`: it orders sessions, fits as many as the
# client is wide, and writes `status-format[0]`.
for hook in client-attached client-session-changed client-resized \
            session-created session-closed window-unlinked window-linked; do
  tmux set-hook -g "${hook}" "run-shell ${scripts}/tmux-status-viewport"
done


# BINDINGS

# Killing the session the client sits on detaches it, ending tmux. `off` sends the client to the
# most recently used session instead, and only detaches once no session is left.
tmux set-option -g detach-on-destroy off

# Keys are opt-in: every key worth binding here already means something in tmux, so the plugin
# picks none and leaves the choice to the config. `README.md` suggests a set. An unset option
# binds nothing.
#   bind-session-key <option> <description> [-r] <tmux-command>...
bind-session-key() {
  local option="$1" note="$2"
  shift 2

  local flags
  flags=()
  if [[ "$1" == "-r" ]]; then
    flags=(-r)
    shift
  fi

  local key
  key="$(tmux show-option -gqv "${option}")"
  if [[ -z "${key}" ]]; then
    return
  fi

  tmux bind -N "${note}" "${flags[@]}" "${key}" "$@"
}

bind-session-key @session-new-key "Create a session" \
    new-session

bind-session-key @session-kill-key "Kill current session" \
    confirm-before kill-session

bind-session-key @session-last-key "Select last active session" \
    switch-client -l

# Name a session on the status line, and rename the session to match. Empty = cwd on the line, and
# a number for the name.
bind-session-key @session-label-key "Label the current session" \
    command-prompt -I "#{@label}" -p "(label)" "run-shell '${scripts}/tmux-label-session \"%%\"'"

bind-session-key @session-prev-key "Select the previous session" -r \
    run-shell "${scripts}/tmux-select-session prev"

bind-session-key @session-next-key "Select the next session" -r \
    run-shell "${scripts}/tmux-select-session next"

bind-session-key @session-move-left-key "Move session left" -r \
    run-shell "${scripts}/tmux-move-session left"

bind-session-key @session-move-right-key "Move session right" -r \
    run-shell "${scripts}/tmux-move-session right"

# Clicks are not configurable: they are bound to the status line itself, not to a key the config
# could want back.

# Click a session or one of its windows in the status line to focus it. The whole command sits in
# the `run-shell` argument, the only part expanded with the mouse in context (`-t` takes its
# argument as-is, `if -F` reads the range as empty). A click off any range runs `true`.
tmux bind -n MouseDown1Status run-shell \
    '#{?mouse_status_range,tmux switch-client -c #{q:client_tty} -t #{q:mouse_status_range},true}'

# Middle click to kill session/window. The inner quotes stay single: the range holds a session id
# like `$3`, which a double-quoted shell string would expand away.
tmux bind -n MouseDown2Status run-shell "#{?mouse_status_range,tmux confirm-before -t #{q:client_tty} -p 'Kill #{mouse_status_range}? (y/n)' '#{?#{m:*:*,#{mouse_status_range}},kill-window,kill-session} -t #{mouse_status_range}',true}"


# Runs last: it measures sessions with the format just defined.
"${scripts}/tmux-status-viewport"
