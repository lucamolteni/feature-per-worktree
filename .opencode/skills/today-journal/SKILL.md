---
name: today-journal
description: Use when the user asks for today's journal, today's work summary, or invokes /today-journal; scan active feature and archived journal entries and write a concise summary
---

# Today Journal

Usage: `/today-journal`

Produces a bullet-point summary of today's work across all features.

## Steps

1. Determine today's date:
   ```bash
   date "+%Y-%m-%d"
   ```

2. Scan for today's journal entries in the active feature and archived journal directories. Start `find` only at the journal directories so it does not traverse complete feature worktrees:
   ```bash
   find "$HOME/git/hibernate"/*/journal \
        "$HOME/git/hibernate"/journal/*/events \
        -type f -name "$(date +%Y-%m-%d).md" \
        ! -path "$HOME/git/hibernate/main/journal/*" -print 2>/dev/null
   ```

3. Read all matching journal files. If none exist, say so and stop.

4. Produce the summary using this format:

```
# YYYY-MM-DD

- QUARKUS-48005:
  - First bullet point about what was done
  - Second bullet point
  - Third bullet point
- QUARKUS-53413:
  - First bullet point
  - Second bullet point
```

   The summary should:
   - Use a top-level `#` heading with the date
   - Use a top-level bullet per feature (e.g., `- QUARKUS-48005:`)
   - Use indented sub-bullets for each key activity
   - Cover all entries from all features, not just the latest one
   - Be concrete: mention what was built, fixed, refactored, or discovered

5. Write the summary to a temp file. After writing, resolve the real path and give the user that absolute path:
   ```bash
   cat > $TMPDIR/today-journal.md <<'EOF'
   <summary>
   EOF
   JOURNAL_PATH=$(realpath $TMPDIR/today-journal.md)
   ```

6. Print the summary, then tell the user to run using the resolved absolute path (NOT `$TMPDIR`):
   ```
   pbcopy < /absolute/path/to/today-journal.md
   ```
