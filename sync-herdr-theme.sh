#!/usr/bin/env bash
# Sync Herdr UI theme with host light/dark appearance.
#
# Herdr's auto_switch relies on CSI 2031 / host color-scheme reports.
# WezTerm does not implement CSI 2031 yet (wezterm/wezterm#6454), so Herdr
# cannot detect appearance on its own. Grok TUI works because it reads
# macOS AppleInterfaceStyle directly — this script bridges that gap for Herdr.
#
# Usage: sync-herdr-theme.sh dark|light
set -euo pipefail

MODE="${1:-}"
CONFIG="${HERDR_CONFIG_PATH:-$HOME/.config/herdr/config.toml}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/wezterm"
STATE_FILE="$STATE_DIR/herdr-theme.mode"
HERDR_BIN="${HERDR_BIN:-/opt/homebrew/bin/herdr}"

DARK_THEME="tokyo-night"
LIGHT_THEME="tokyo-night-day"

case "$MODE" in
dark)
	THEME="$DARK_THEME"
	;;
light)
	THEME="$LIGHT_THEME"
	;;
*)
	echo "usage: $0 dark|light" >&2
	exit 2
	;;
esac

mkdir -p "$STATE_DIR"

# Skip if we already applied this mode (avoids reload storms).
if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "$MODE" ]]; then
	# Still ensure config matches in case the user edited it.
	if [[ -f "$CONFIG" ]] && grep -qE "^name = \"${THEME}\"" "$CONFIG"; then
		exit 0
	fi
fi

if [[ ! -f "$CONFIG" ]]; then
	echo "herdr config not found: $CONFIG" >&2
	exit 1
fi

tmp="$(mktemp "${CONFIG}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

# Force manual theme selection: auto_switch cannot work under WezTerm.
# Keep dark_name/light_name for documentation / future CSI 2031 support.
awk -v theme="$THEME" '
BEGIN { in_theme = 0; saw_name = 0; saw_auto = 0 }
/^\[theme\]/ {
	in_theme = 1
	print
	next
}
/^\[/ {
	if (in_theme) {
		if (!saw_name) print "name = \"" theme "\""
		if (!saw_auto) print "auto_switch = false"
	}
	in_theme = 0
	print
	next
}
in_theme && /^name[[:space:]]*=/ {
	print "name = \"" theme "\""
	saw_name = 1
	next
}
in_theme && /^auto_switch[[:space:]]*=/ {
	print "auto_switch = false"
	saw_auto = 1
	next
}
{ print }
END {
	if (in_theme) {
		if (!saw_name) print "name = \"" theme "\""
		if (!saw_auto) print "auto_switch = false"
	}
}
' "$CONFIG" >"$tmp"

# Only rewrite + reload when content actually changes.
if ! cmp -s "$CONFIG" "$tmp"; then
	mv "$tmp" "$CONFIG"
	trap - EXIT
	if [[ -x "$HERDR_BIN" ]]; then
		# Best-effort: server may not be running outside a herdr session.
		"$HERDR_BIN" server reload-config >/dev/null 2>&1 || true
	fi
else
	rm -f "$tmp"
	trap - EXIT
fi

printf '%s\n' "$MODE" >"$STATE_FILE"
