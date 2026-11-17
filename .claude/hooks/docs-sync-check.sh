#!/usr/bin/env bash
# Stop hook: ask Claude to run the sync-docs skill when files changed after
# SESSIONS.md was last modified. Silent (exit 0, no output) otherwise.

input=$(cat)

# Already continuing because of this hook: don't loop.
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0

log=SESSIONS.md
stale=()
while IFS= read -r line; do
  path=${line:3}
  path=${path##* -> }          # renames: keep the new path
  path=${path#\"}; path=${path%\"}
  case "$path" in
    "$log"|*/.gitkeep|.gitkeep) continue ;;
  esac
  [ -f "$path" ] || continue   # deletions
  if [ ! -f "$log" ] || [ "$path" -nt "$log" ]; then
    stale+=("$path")
  fi
done < <(git status --porcelain -uall)

[ ${#stale[@]} -eq 0 ] && exit 0

list=$(printf '%s, ' "${stale[@]:0:10}"); list=${list%, }
[ ${#stale[@]} -gt 10 ] && list="$list, and $(( ${#stale[@]} - 10 )) more"

reason="Files changed after SESSIONS.md was last updated ($list). Run the sync-docs skill to update SESSIONS.md and any affected docs, then stop."
reason=${reason//\\/\\\\}; reason=${reason//\"/\\\"}
printf '{"decision":"block","reason":"%s"}\n' "$reason"
