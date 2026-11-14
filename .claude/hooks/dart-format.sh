#!/usr/bin/env bash
# PostToolUse: format the edited Dart file (generated *.g.dart files are left alone).
file=$(jq -r '.tool_input.file_path // empty')
[[ "$file" == *.dart && "$file" != *.g.dart && -f "$file" ]] || exit 0
"$HOME/.local/share/geokuna/flutter/bin/dart" format "$file" >/dev/null 2>&1 || true
