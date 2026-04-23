---
name: today-journal
description: Use when the user wants a quick summary of today's work from journal entries
---

# Today Journal

Usage: `/today-journal`

Produces a bullet-point summary of today's work across all features.

## Steps

1. Determine today's date:
   ```bash
   date "+%Y-%m-%d"
   ```

2. Scan for today's journal entries in two places:
   - **Active features**: check `~/git/hibernate/*/journal/YYYY-MM-DD.md`
   - **Archived journals**: check `~/git/hibernate/journal/*/events/YYYY-MM-DD.md`
   ```bash
   find ~/git/hibernate -maxdepth 3 -path '*/journal/*.md' -name "$(date +%Y-%m-%d).md"
   find ~/git/hibernate/journal -maxdepth 3 -path '*/events/*.md' -name "$(date +%Y-%m-%d).md"
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

5. Copy the summary to the clipboard:
   ```bash
   echo "<summary>" | pbcopy
   ```

6. Print the summary and confirm it was copied to the clipboard.
