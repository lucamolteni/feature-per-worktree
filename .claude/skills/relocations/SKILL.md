---
name: relocations
description: Generate Maven artifact relocations for renamed Quarkus extensions, including BOM entries and OpenRewrite recipes
user_invocable: true
---

# Relocations

Usage: `/relocations <feature-number> <quarkus-version>` (e.g., `/relocations 39 3.31`)

Generates Maven artifact relocations when Quarkus extensions are renamed. Produces relocation POMs, BOM entries, migration guide tables, and OpenRewrite recipes for quarkus-updates.

## Prerequisites

- Feature directory `~/git/hibernate/<number>/` must exist.
- A Quarkus worktree for the feature must exist at `<number>/quarkus/` (the branch where the rename was done) OR the rename must already be merged to upstream/main.
- A separate Quarkus worktree at `<number>/relocations/` must exist for the relocation work. If it does not exist, tell the user to create one:
  ```
  cd ~/git/hibernate/main/quarkus
  git worktree add -b relocations ~/git/hibernate/<number>/relocations upstream/main
  ```
  Then set up `.mvn/maven.config` with `-Dmaven.repo.local` pointing to `<number>/.m2`.

## Steps

1. **Auto-detect renamed artifacts**. Compare the feature's quarkus worktree (or upstream/main if the rename is merged) against the relocations worktree to find artifact ID changes in extension pom.xml files:
   ```bash
   # Find old artifact IDs that no longer exist and new ones that replaced them
   # Look at bom/application/pom.xml diffs, extension pom.xml changes, etc.
   ```
   Present the detected old-to-new mappings to the user and ask for confirmation before proceeding. The user may add, remove, or correct mappings.

2. **Add entries to generaterelocations.java**. Edit `<number>/relocations/relocations/generaterelocations.java` to add the new relocations to the `RELOCATIONS` static map. Follow the existing pattern:
   ```java
   Function<String, Relocation> myRelocation = a -> Relocation.ofArtifactId(a,
           a.replace("old-name-part", "new-name-part"), "<quarkus-version>");
   RELOCATIONS.put("quarkus-old-name", myRelocation);
   RELOCATIONS.put("quarkus-old-name-deployment", myRelocation);
   ```
   Use the appropriate factory method:
   - `Relocation.ofArtifactId(old, new, version)` -- only artifactId changed
   - `Relocation.ofGroupId(old, newGroup, version)` -- only groupId changed
   - `Relocation.of(old, newGroup, newArtifact, version)` -- both changed

   **Important**: The version passed here is the **upcoming Quarkus release** where the rename ships. This version controls the migration guide URL in the generated relocation POMs (e.g., `Migration-Guide-3.37`). It must match the version used for the quarkus-updates recipe file in step 5. Ask the user which version to use if unclear.

3. **Run the generator**:
   ```bash
   cd ~/git/hibernate/<number>/relocations/relocations
   jbang generaterelocations.java
   ```
   This produces:
   - Relocation POM directories under `relocations/`
   - Updated `relocations/pom.xml` with new module entries
   - Printed migration guide asciidoc tables (capture for wiki)
   - Printed OpenRewrite recipe YAML (capture for quarkus-updates)

4. **Add relocations to the BOM**. Edit `<number>/relocations/bom/application/pom.xml`. Find the `<!-- Relocations -->` section near the end and add new entries before `<!-- End of Relocations, please put new extensions above this list -->`:
   ```xml
   <dependency>
       <groupId>io.quarkus</groupId>
       <artifactId>quarkus-old-name</artifactId>
       <version>${project.version}</version>
   </dependency>
   ```
   Add one entry per relocated artifact (both runtime and deployment).

5. **Create OpenRewrite recipe in quarkus-updates** (if worktree exists). If `<number>/quarkus-updates/` exists:

   **Important**: The recipe file version must match the **upcoming Quarkus release** where the rename will ship, NOT the version used in `generaterelocations.java`. The version in the generator is for the relocation POM metadata; the quarkus-updates version is for the migration tooling. Ask the user which upcoming Quarkus version to target if unclear.

   Create a **new** file (do not append to existing version files for old releases):
   ```
   <number>/quarkus-updates/recipes/src/main/resources/quarkus-updates/core/<upcoming-version>.alpha1.yaml
   ```
   Use a comment header and a unique recipe name with the version number (dots removed):
   ```yaml
   #####
   # Relocations for <description>
   #####
   ---
   type: specs.openrewrite.org/v1beta/recipe
   name: io.quarkus.updates.core.quarkus<version-no-dots>.MyRelocations
   recipeList:
     ...
   ```
   If the quarkus-updates worktree does not exist, print the recipe YAML and tell the user to add it manually.

   **Package and class renames**: If the rename also changed Java package names or class names of API types consumed by end users, add additional OpenRewrite recipes to the same file:
   - To rename an entire package, use `org.openrewrite.java.ChangePackage`:
     ```yaml
     - org.openrewrite.java.ChangePackage:
         oldPackageName: io.quarkus.old.package
         newPackageName: io.quarkus.new.package
         recursive: true
     ```
   - If individual class names also changed, use `org.openrewrite.java.ChangeType`:
     ```yaml
     - org.openrewrite.java.ChangeType:
         oldFullyQualifiedTypeName: io.quarkus.old.package.OldClassName
         newFullyQualifiedTypeName: io.quarkus.new.package.NewClassName
     ```
   Only include these for types that are considered public API and consumed by end users, not internal/deployment classes. Ask the user whether any packages or class names were renamed.

6. **Update the migration guide wiki**. The generator prints two asciidoc tables — one for publicly consumed modules, one for extension developers. These must be added to the Quarkus migration guide wiki page at `https://github.com/quarkusio/quarkus/wiki/Migration-Guide-<quarkus-version>`. Print both tables and remind the user to paste them into the wiki under an appropriate section heading.

7. **Summarize**. Print:
   - What relocation POMs were generated
   - What was added to the BOM
   - Whether the quarkus-updates recipe was written or needs manual action
   - The asciidoc tables to add to the migration guide wiki
   - Remaining manual steps: commit, create PR on quarkus, create PR on quarkus-updates, update wiki
