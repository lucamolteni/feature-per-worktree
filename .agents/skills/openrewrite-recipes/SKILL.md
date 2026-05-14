# OpenRewrite Recipe Writing

When writing OpenRewrite YAML recipes (`.yml` files with `type: specs.openrewrite.org/v1beta/recipe`), always prefer proper OpenRewrite recipes over shell script workarounds. The recipe should do as much as possible; the shell script should only invoke `mvn rewrite:run`.

## Reference Docs

Full recipe documentation is checked out at `main/rewrite-docs/docs/recipes/`. **Always check the docs before guessing at recipe syntax or options.** Key directories:

- `main/rewrite-docs/docs/recipes/maven/` — Maven POM manipulation
- `main/rewrite-docs/docs/recipes/xml/` — XML file manipulation
- `main/rewrite-docs/docs/recipes/java/` — Java source manipulation
- `main/rewrite-docs/docs/recipes/text/` — Plain text file manipulation
- `main/rewrite-docs/docs/recipes/core/` — File operations (move, rename, delete)

Each `.md` file documents one recipe with its options, examples, and usage.

## Available Recipes — Quick Reference

### Core (files and directories)

| Recipe | What it does | Key options |
|--------|-------------|-------------|
| `org.openrewrite.MoveFile` | Move files/directories | `folder` (source dir), `fileMatcher` (glob), `moveTo` (relative dest). With `folder`, moves all files+subfolders. |
| `org.openrewrite.RenameFile` | Rename a file in place | `fileMatcher` (glob), `fileName` (new name) |
| `org.openrewrite.DeleteSourceFiles` | Delete files matching a pattern | |

### Maven POM manipulation

| Recipe | What it does |
|--------|-------------|
| `ChangeDependencyGroupIdAndArtifactId` | Rename a dependency. Also updates `<dependencyManagement>` if `changeManagedDependency: true`. |
| `ChangeParentPom` | Change an existing `<parent>` by matching old groupId+artifactId to new. Has `oldRelativePath`/`newRelativePath`. |
| `AddParentPom` | Add a `<parent>` to a POM that has none. Does nothing if parent already present. |
| `ChangePackaging` | Set or change `<packaging>` (e.g. `pom`, `jar`). Matches by groupId+artifactId. |
| `AddDependency` | Add a new dependency. |
| `RemoveDependency` | Remove a dependency by groupId+artifactId. |
| `AddProperty` | Add a `<properties>` entry. |
| `ChangePropertyValue` | Change value of an existing property. |
| `RemoveProperty` | Remove a property. |
| `RenamePropertyKey` | Rename a property key. |
| `AddPlugin` | Add a Maven plugin. |
| `RemovePlugin` | Remove a Maven plugin. |
| `ChangeProjectVersion` | Change `<version>` of the project. |
| `UpgradeDependencyVersion` | Upgrade a dependency to a newer version. |
| `UpgradeParentVersion` | Upgrade parent POM version. |
| `ChangeManagedDependencyGroupIdAndArtifactId` | Rename managed dependency. |

All Maven recipes are under `org.openrewrite.maven.*`.

### XML

| Recipe | What it does | Key options |
|--------|-------------|-------------|
| `ChangeTagValue` | Change text content of an XML tag by XPath | `elementName` (XPath), `oldValue`, `newValue`, `regex` (optional) |
| `AddOrUpdateChildTag` | Add or replace a child element under a parent matched by XPath | `parentXPath`, `newChildTag`, `replaceExisting` |
| `RemoveXmlTag` | Remove tags matching XPath | `xPath`, `fileMatcher` |
| `CreateXmlFile` | Create a new XML file from raw content | `relativeFileName`, `fileContents`, `overwriteExisting` |
| `ChangeTagName` | Change an XML tag's element name | |
| `ChangeTagAttribute` | Change/add an attribute on a tag | |

All XML recipes are under `org.openrewrite.xml.*`.

### Java

| Recipe | What it does | Key options |
|--------|-------------|-------------|
| `ChangeType` | Rename a class (updates all references/imports) | `oldFullyQualifiedTypeName`, `newFullyQualifiedTypeName`, `ignoreDefinition` |
| `ChangePackage` | Rename a package (package statements, imports, FQNs) | `oldPackageName`, `newPackageName`, `recursive` |
| `ChangePackageInStringLiteral` | Rename package references inside String literals | `oldPackageName`, `newPackageName` |
| `ReplaceStringLiteralValue` | Replace complete String literal values | `oldLiteralValue`, `newLiteralValue` |
| `ChangeMethodName` | Rename a method | |
| `RemoveAnnotation` | Remove an annotation | |

All Java recipes are under `org.openrewrite.java.*`.

### Text (non-Java, non-XML files)

| Recipe | What it does | Key options |
|--------|-------------|-------------|
| `FindAndReplace` | Find and replace text in files matching a glob | `find`, `replace`, `filePattern`, `regex` (optional) |
| `CreateTextFile` | Create a new text file | |
| `AppendToTextFile` | Append content to a text file | |

All text recipes are under `org.openrewrite.text.*`.

## Key Principles

1. **Prefer semantic recipes over text manipulation.** Use `ChangeDependencyGroupIdAndArtifactId` instead of `FindAndReplace` on pom.xml. Use `ChangeType` instead of `FindAndReplace` on Java files. Use `ChangeTagValue` instead of `FindAndReplace` on XML.

2. **Prefer Maven recipes over CreateXmlFile for POM creation.** To create a new aggregator POM, consider whether the existing POM being moved can be modified in-place (via `ChangeParentPom`, `ChangeTagValue`, `ChangePackaging`) rather than writing raw XML with `CreateXmlFile`.

3. **Use `MoveFile` with `folder` to move entire module directories.** This is the proper way — no shell `mv` needed. The `moveTo` path is relative to the source folder.

4. **`FindAndReplace` cannot touch Java source files.** Use `ReplaceStringLiteralValue` or `ChangeType` or `ChangePackageInStringLiteral` for Java. `FindAndReplace` only works on files registered via `-Drewrite.plainTextMasks`.

5. **Order matters in recipe lists.** Put structural changes (create files, move directories) before content changes. Put broader patterns after specific ones to avoid double-replacement.

6. **The shell script should be minimal.** Ideally just the `mvn rewrite:run` invocation. If a shell workaround (`sed`, `mv`, `mkdir`) is needed, add a comment explaining which OpenRewrite recipe was tried and why it didn't work.

7. **When unsure about a recipe's options, read the doc file** at `main/rewrite-docs/docs/recipes/<category>/<recipename>.md` before guessing.

8. **`filePattern` uses semicolons `;` as separators, NOT commas.** Multiple patterns must be separated by `;`. Example: `"**/*.adoc;**/*.yaml;**/*.yml"`. Using commas silently matches only the first pattern.

## Running Recipes in Quarkus

Standard invocation pattern:

```bash
mvn -B org.openrewrite.maven:rewrite-maven-plugin:run \
    -Drewrite.activeRecipes=<recipe-name> \
    -Drewrite.configLocation="<path-to-yml>" \
    -Drewrite.plainTextMasks="**/*.adoc,**/*.yaml,**/*.yml,..." \
    -Dmaven.test.skip=true \
    -Dmaven.main.skip=true \
    -Dexec.skip=true \
    -pl <comma-separated-module-list>
```

Key flags:
- `-Drewrite.plainTextMasks` — required for `FindAndReplace` to work on non-Java/non-XML files
- `-pl` — limits which modules the recipe runs on (important for performance in Quarkus)
- `-Dmaven.main.skip=true -Dmaven.test.skip=true` — skip compilation
- `-Dexec.skip=true` — prevents the docs module from trying to execute plugins
