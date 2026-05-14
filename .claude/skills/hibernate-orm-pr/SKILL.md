---
name: hibernate-orm-pr
description: Create a PR on hibernate/hibernate-orm with correct commit message format, license agreement, and contribution rules
user_invocable: true
---

# Hibernate ORM PR

Usage: `/hibernate-orm-pr <jira-key> <branch-name> [base-branch]`

Example: `/hibernate-orm-pr HHH-20384 converter-interface-exclusion 7.3`

Creates a pull request on `hibernate/hibernate-orm` following the project's contribution rules.

- `<jira-key>`: JIRA issue key (e.g., `HHH-20384`). Required.
- `<branch-name>`: The local branch to push and create the PR from.
- `[base-branch]`: Target branch on upstream. Defaults to `main`.

## Contribution Rules (from hibernate-orm CONTRIBUTING.md)

These are enforced by the `hibernate-github-bot` and will block merge if violated:

1. **Commit message prefix**: Every commit message MUST start with the JIRA issue key matching `HHH-\d+`. Example: `HHH-20384 Fix converter categorization`.
2. **License agreement in PR description**: The PR body MUST contain the following text block verbatim:

```
----------------------
By submitting this pull request, I confirm that my contribution is made under the terms of the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0.txt)
and can be relicensed under the terms of the [LGPL v2.1 license](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt) in the future at the maintainers' discretion.
For more information on licensing, please check [here](https://github.com/hibernate/hibernate-orm/blob/main/CONTRIBUTING.md#legal).

----------------------
```

3. **Code style**: Run `./gradlew formatChecks` before committing (spotless + checkstyle).
4. **Tests required**: Include tests that demonstrate the fix or feature.
5. **Branch naming convention**: Use the JIRA key in branch names when possible (e.g., `HHH-20384-converter-fix`), though this is a convention not a hard rule.

## Steps

1. **Validate commit messages**: Check that all commits on the branch (compared to the base) start with the JIRA key pattern `HHH-\d+`. If any commit does not match, amend or reword before proceeding. Ask the user before rewriting.

2. **Push the branch**:
   ```bash
   cd <worktree-path>
   git push -u origin <branch-name>
   ```

3. **Create the PR** using `gh pr create`:
   - `--repo hibernate/hibernate-orm`
   - `--base <base-branch>`
   - `--head lucamolteni:<branch-name>`
   - Title should start with the JIRA key: `<jira-key> <short description>`
   - Body must include:
     - A summary section describing the change
     - Any cross-references (Quarkus issues, other PRs)
     - The license agreement block (verbatim, as shown above)

4. **Verify**: Fetch the PR URL and confirm the bot has not flagged any issues. If it has, fix them immediately.

## Template

```
gh pr create --repo hibernate/hibernate-orm --base <base-branch> --head lucamolteni:<branch-name> --title "<jira-key> <title>" --body "$(cat <<'EOF'
## Summary
- <bullet points describing the change>

<any cross-references: Needed for quarkusio/quarkus#XXXXX, etc.>

----------------------
By submitting this pull request, I confirm that my contribution is made under the terms of the [Apache 2.0 license](https://www.apache.org/licenses/LICENSE-2.0.txt)
and can be relicensed under the terms of the [LGPL v2.1 license](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt) in the future at the maintainers' discretion.
For more information on licensing, please check [here](https://github.com/hibernate/hibernate-orm/blob/main/CONTRIBUTING.md#legal).

----------------------
EOF
)"
```
