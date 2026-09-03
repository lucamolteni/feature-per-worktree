# Create Hibernate Jira Issue

Usage: `/create-hibernate-jira <summary>`

Creates a bug issue on the Hibernate ORM Jira project (HHH).

## Steps

1. **Gather context from the conversation.** Build a description from:
   - What the bug is (the symptom)
   - A minimal code example showing the problem
   - What happens vs what should happen
   - Which classes/methods are involved

2. **Ask the user to confirm** the summary and description before creating.

3. **Create the issue** using:
   ```bash
   acli jira workitem create \
     --project "HHH" \
     --type "Bug" \
     --summary "<summary>" \
     --description "<description>"
   ```

4. **Print the issue key and URL** returned by the command.

## Description Guidelines

- Keep the description factual and concise
- Include a minimal reproducer code snippet
- Describe the symptom (e.g. "throws UnknownNamedQueryException")
- Mention which classes are involved (e.g. "QueryBinder.bindStaticQueries()")
- Do NOT include the fix or proposed solution in the description
- Do NOT include Quarkus-specific details -- frame the issue in pure Hibernate terms
- Escape double quotes in the description with backslash for the shell command

## Notes

- The project key is always HHH (Hibernate ORM)
- The type is always Bug unless the user specifies otherwise
- The `acli` CLI must be authenticated (`acli jira auth`)
