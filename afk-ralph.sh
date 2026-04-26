#!/usr/bin/env bash
# afk-ralph.sh — Autonomous Ralph loop.
# Usage: ./afk-ralph.sh [max_iterations]
# Example: ./afk-ralph.sh 15
# Runs up to N iterations, stopping early if all tasks complete.

set -e

MAX=${1:-15}
echo "Starting AFK Ralph — up to $MAX iterations"
echo "Press Ctrl+C to stop at any time."
echo ""

for ((i=1; i<=MAX; i++)); do
  echo "━━━ Iteration $i / $MAX ━━━"

  result=$(claude --permission-mode acceptEdits -p \
"@ralph/PRD.md @ralph/progress.txt @docs/superpowers/plans/2026-04-26-ui-ux-redesign.md @docs/superpowers/specs/2026-04-26-ui-ux-redesign-design.md

You are implementing the CodeKata UI redesign one task at a time.

## Instructions

1. Read progress.txt to see what has already been completed.
2. From PRD.md, pick the next INCOMPLETE task whose blockers are all done.
3. Read the relevant task section in the plan file for the EXACT code to write.
4. Implement the task — write the files exactly as specified in the plan.
5. Run the feedback loop (see below).
6. Make a git commit with a descriptive message.
7. Append an entry to ralph/progress.txt marking the task complete.
8. STOP. Do not start the next task.

If ALL tasks are complete, output: <promise>COMPLETE</promise>

## Feedback Loop

After writing each ERB file, verify it has no Ruby syntax errors:
  ruby -e \"require 'erb'; ERB.new(File.read('PATH_TO_FILE')).src\" 2>&1

If the database is running, also run:
  SKIP_SANITY_CHECK=true bin/rails test

Do NOT commit if the feedback loop fails. Fix the issue first.

## Rules

- ONLY work on ONE task per invocation.
- Do NOT change controllers, models, routes, or Turbo wiring.
- Preserve all existing Turbo Frame tags, Turbo Stream subscriptions, and button_to forms exactly.
- Use plain HTML <a> tags for nav links (not link_to blocks with do...end).
- Keep data-turbo-method=\"delete\" on the logout link.
- Do not introduce new dependencies.")

  if [[ "$result" == *"<promise>COMPLETE</promise>"* ]]; then
    echo ""
    echo "✓ All tasks complete."
    exit 0
  fi

  echo ""
done

echo "Reached $MAX iterations. Run again to continue."
