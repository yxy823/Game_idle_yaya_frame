# Godot Version and Authority

Defines how target-version facts and engineering evidence are established.

## Target version

- **[MUST]** The project's target version line is Godot 4.7. Project tooling and configuration own the exact approved patch executables.
- **[MUST]** Do not change the target Godot version, the executable baseline, the renderer baseline or the upgrade state merely to simplify the current task.
- **[MUST]** For API and engine semantics, prefer the versioned Godot 4.7 official documentation and class reference.
- **[MUST]** Do not use `/latest/`, Godot 3.x or an example from another minor version as proof that an API or behavior exists in Godot 4.7. Treat it as discovery material and verify it against 4.7.
- **[MUST]** Treat a minor or patch upgrade as migration work when behavior is version-sensitive. Do not assume that all Godot 4.x or all 4.7.x behavior is identical.

## Authority and evidence

- **[MUST]** Versioned official Godot documentation defines the intended semantics of the target engine.
- **[MUST]** The actual target Godot compiler, parser, importer, runtime, renderer and exporter provide executable evidence for the project.
- **[MUST]** A discrepancy between documentation and runtime is a verification problem, not a shortcut to choose whichever behavior is convenient.
- **[MUST]** For a material discrepancy, confirm the exact versions. Use a minimal reproduction plus migration notes, engine source or known issues as needed to classify it as an engine bug, a documentation defect, a patch difference, a configuration problem or project misuse.
- **[REVIEW]** Isolate a workaround for a confirmed defect in the target engine version, and document the version and condition it applies to. Add a regression test where practical, and give it a recheck or removal condition when useful.

## External references

- **[PREFER]** Mature third-party Godot projects may inform engineering practice, failure modes and validation strategy.
- **[MUST]** Third-party practice does not override target Godot semantics, explicit project architecture or applicable Core `[MUST]` rules.
- **[MUST]** Third-party plugin and tool documentation must match the version that the project actually uses; do not assume that the latest documentation matches the installed version.
- **[PREFER]** Blogs, forums and community posts may identify candidate pitfalls. Verify their version-sensitive factual claims before turning them into project rules.
- **[MUST]** When correctness depends on a version-sensitive Godot or tool fact and that fact is uncertain, verify it instead of guessing.
- **[PREFER]** Record the exact tested Godot or tool version when the result is materially version-sensitive.
