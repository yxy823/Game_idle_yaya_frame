# Export Resources and Filters

Export selection determines the real production package; editor visibility is not evidence of package content.

## Packaging

- **[MUST]** The Resource and filter policy is a runtime packaging contract.
- **[MUST]** Raw non-Resource files opened through FileAccess (`.json`, `.csv`, `.txt` and similar) need an explicit export inclusion policy, or conversion to a packaged Resource.
- **[MUST]** Files and directories whose names begin with `.` are not included in a Godot exported project, and include filters do not override this boundary. Runtime-required data must not depend on a dot-prefixed path.
- **[MUST]** Verify runtime-required raw data in the actual package. A broad include filter or readability in the editor is not evidence that a dot-prefixed or otherwise filtered path was exported.
- **[REVIEW]** When exporting only selected scenes or resources, audit dynamic loads, registries, runtime paths and raw-file dependencies that static dependency traversal may not discover.
- **[MUST]** Do not use broad or unclear include and exclude filters merely to shrink or clean up the package.

## Dedicated server

- **[MUST]** Treat a dedicated-server preset as a distinct runtime artifact contract, not as a general optimization of package size.
- **[REVIEW]** A dedicated-server export strips visual Resources or replaces them with placeholders, including `Material`, `Mesh`, `Texture2D`, `Texture3D` and `Cubemap`. Audit the server's runtime dependencies, and explicitly keep any Resource whose data is still required.
- **[MUST]** Validate a dedicated-server change with the actual server export plus a defined server startup or smoke path; a normal client export does not prove the server artifact.

## Test and addon isolation

- **[MUST]** Classify addons and resources as test-only, editor-only or runtime-required before excluding them. `addons/` is not automatically safe to exclude wholesale.
- **[MUST]** The production export excludes test roots, test fixtures and test-only frameworks and tooling according to project policy.
- **[MUST]** Excluding a file does not remove project or runtime references to it. Validate that the production configuration has no dependency on excluded test or editor artifacts.
