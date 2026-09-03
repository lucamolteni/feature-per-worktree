---
name: yesterday-journal
description: Use when the user wants a quick summary of yesterday's work from journal entries
---

# Yesterday Journal

Usage: `/yesterday-journal` or `/yesterday-journal 2026-05-15`

Use the `today-journal` skill but with yesterday's date instead of today's. If the user passes a date argument, use that date instead.

Default date (no argument): `date -v-1d "+%Y-%m-%d"`
