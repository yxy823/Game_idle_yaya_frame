# Godot Version and Authority

Defines how target-version facts and engineering evidence are established.

## Target version

- **[MUST]** The project target version line is Godot 4.7. Exact approved patch executable(s) are owned by project tooling/configuration.
- **[MUST]** Do not change the target Godot version, executable baseline, renderer baseline, or upgrade state merely to simplify the current task.
- **[MUST]** Prefer versioned Godot 4.7 official documentation/class reference for API and engine semantics.
- **[MUST]** Do not use `/latest/`, Godot 3.x, or another minor-version example as proof that an API or behavior exists in Godot 4.7. Treat it as discovery material and verify against 4.7.
- **[MUST]** Minor/patch upgrades are migration work when behavior is version-sensitive; do not assume all Godot 4.x or all 4.7.x behavior is identical.

## Authority and evidence

- **[MUST]** Versioned official Godot documentation defines intended target-engine semantics.
- **[MUST]** The actual target Godot compiler/parser/importer/runtime/renderer/exporter provides executable evidence for the project.
- **[MUST]** A documentation/runtime discrepancy is a verification problem, not a shortcut to choose whichever behavior is convenient.
- **[MUST]** For a material discrepancy, confirm exact versions and use a minimal reproduction plus migration notes/source/known issues as needed to classify bug, documentation defect, patch difference, configuration problem, or project misuse.
- **[REVIEW]** A workaround for a confirmed target-version engine defect should be isolated, version/condition documented, regression-tested where practical, and given a recheck/removal condition when useful.

## External references

- **[PREFER]** Mature third-party Godot projects may inform engineering practice, failure modes, and validation strategy.
- **[MUST]** Third-party practice does not override target Godot semantics, explicit project architecture, or applicable Core `[MUST]` rules.
- **[MUST]** Third-party plugin/tool documentation must match the version actually used by the project; do not assume latest documentation matches the installed version.
- **[PREFER]** Blogs/forums/community posts may identify candidate pitfalls, but version-sensitive factual claims should be verified before becoming project rules.
- **[MUST]** When correctness depends on a version-sensitive Godot/tool fact and that fact is uncertain, verify it instead of guessing.
- **[PREFER]** Record the exact tested Godot/tool version when the result is materially version-sensitive.
