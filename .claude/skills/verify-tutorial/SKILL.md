---
name: verify-tutorial
description: Verify that a step-by-step tutorial file is actually runnable by checking every code block sequentially for missing dependencies, imports, classes, files, and API misuse
user_invocable: true
---

# Verify Tutorial

Usage: `/verify-tutorial <path-to-tutorial.adoc>`

Reads a step-by-step tutorial (asciidoc guide), extracts each code block in order, and actually executes the steps in a Quarkus project inside the active feature directory. Every section becomes a checkpoint: apply the code, compile, and report real errors.

## Procedure

### 1. Detect the active feature directory

Determine which feature is active using the same detection as write-journal:

1. Check conversation context for recent file reads or edits in a feature directory (e.g., `39/quarkus-website/...`)
2. If ambiguous or no feature context is found, ask the user which feature to use

The project will be created at `~/git/hibernate/<feature>/verify-tutorial-<timestamp>/`.

### 2. Create a fresh Quarkus project

```bash
FEATURE_DIR="$HOME/git/hibernate/<feature>"
WORK_DIR="$FEATURE_DIR/verify-tutorial-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"
quarkus create app verify-tutorial --no-code
cd verify-tutorial
```

### 3. Parse the tutorial

Read the tutorial file. Extract code blocks in document order, noting:
- The section heading each block belongs to
- The language tag (`java`, `xml`, `gradle`, `sql`, `properties`, `bash`)
- The file hint if present (e.g., `.pom.xml`, `.build.gradle`, `.application.properties`)
- The surrounding prose (for context on deliberate errors)

### 4. Walk through each section

For each section, apply the code blocks to the project and try to compile. The steps depend on the block type:

#### XML blocks (pom.xml)
- If it contains `<dependency>`, add it to the project's `pom.xml` inside `<dependencies>`
- If it contains `<plugin>`, add it to the project's `pom.xml` inside `<build><plugins>`
- Run `mvn compile` after applying and report any errors

#### Gradle blocks
- Skip if Maven is the primary build. Note for the report that Gradle was not tested.

#### SQL blocks
- Write to `src/main/resources/import.sql` (append if it already exists)

#### Properties blocks
- Write to `src/main/resources/application.properties` (append if it already exists)

#### Java blocks
- Determine the class name from the code (`public class X`, `public interface X`, `record X`)
- Determine the package. If not specified in the block, use `org.acme`
- Add any missing imports that are unambiguous. For ambiguous imports (e.g., `@Find` from hibernate vs jakarta.data), pick the one that matches the repository supertype used in the code, and note the ambiguity in the report.
- Write to `src/main/java/org/acme/<ClassName>.java`
- If the class was already written in a previous step (tutorial evolves it), overwrite the file
- Run `mvn compile` and capture the output
- If compilation fails, report the errors verbatim

#### Bash blocks
- If the command is `quarkus extension add ...`, run it in the project directory
- Otherwise note it as informational and skip

### 5. Handle deliberate errors

Some code blocks contain intentional mistakes (e.g., a typo to demonstrate compile-time validation). Check the surrounding prose:
- If the prose says something like "Did you spot the typo?" or "the build fails", the error is deliberate
- Mark it as INFO in the report instead of ERROR
- Still compile it to verify the error message matches what the tutorial claims

### 6. Handle incremental evolution

The tutorial redefines the same class across sections (e.g., `Book` evolves from plain `@Entity` to `PanacheEntity.Stateless` to `PanacheEntity.Managed`). Each time a class is redefined:
- Overwrite the previous version of the file
- Also update any other files that reference the old version if they would break (e.g., a service calling `.persist()` when the entity changed to `.insert()`)
- If the tutorial does not update a dependent file, report the breakage

### 7. Handle sections with multiple code blocks

Some sections show the same class from different angles (e.g., a comparison between stateless and managed). When a code block is clearly a comparison or "what it would have been" example (check surrounding prose like "Compare it to"), do NOT write it to the project — just note it as a comparison example.

## Report format

After processing each section, output:

```
### Section: "<section title>"

Applied: <what was written/changed>
Compile result: SUCCESS | FAILURE

Errors (if any):
- [ERROR] <compiler error message verbatim>
  File: <file that caused it>

- [INFO] <deliberate error, acknowledged in prose>
  Expected by tutorial: "<prose quote>"
  Actual compiler output: <error message>

Notes:
- [WARNING] <any concern that isn't a compile error but could confuse a user>
```

At the end, print a summary:

```
## Summary
- Sections tested: N
- Compile successes: N
- Compile failures: N (M deliberate, K unexpected)
- Warnings: N
```

## Important

- **Follow the tutorial exactly.** Execute every step as written — do not substitute, work around, or circumvent tutorial instructions. If the tutorial says `quarkus create app --platform-bom=...`, run exactly that. If the tutorial says `quarkus extension add X`, run exactly that. If a step fails, report the failure. Do not try an alternative approach (e.g., adding a dependency to pom.xml manually instead of using the CLI). The whole point is to verify the tutorial as a user would follow it. If it breaks, that's the finding.
- Actually compile the code. Do not speculate about what would or would not compile.
- Use `mvn compile -q` to keep output focused on errors.
- **Always `cd` into the project directory before every command.** Shell state does not persist between tool calls, so every `Bash` invocation must start with `cd /path/to/project &&`. Never assume you are already in the right directory.
- **Run tests, not just compile.** When the tutorial provides test classes, run them with `mvn test -q` (or the specific test class with `-Dtest=ClassName`). The tutorial tells users to run `quarkus test` — since that is a long-running continuous process, use `mvn test` instead to verify tests pass. Report test failures the same way as compile failures.
- Use whatever Quarkus version the tutorial specifies. If the tutorial provides a `--platform-bom` flag or a specific version, use that exactly. Do not override or substitute versions.
- When compilation or tests fail unexpectedly, include the full error output — the user needs to see the actual message to fix the tutorial.
- Create the project in a timestamped folder inside the active feature directory (e.g., `39/verify-tutorial-20260617-143052/`), never in `$TMPDIR` or `/tmp` — this keeps verification artifacts with the feature and avoids sandbox permission issues.
- Do not delete the work directory — leave it for the user to inspect and clean up.
