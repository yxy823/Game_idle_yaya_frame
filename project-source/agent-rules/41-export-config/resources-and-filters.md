# Export Resources and Filters

Export selection determines the real production package; editor visibility is not package evidence.

## Packaging

- **[MUST]** Resource/filter policy is a runtime packaging contract.
- **[MUST]** Raw non-Resource files opened via FileAccess (`.json`, `.csv`, `.txt`, etc.) require explicit export inclusion policy or conversion to a packaged Resource.
- **[MUST]** Files or directories whose names begin with `.` are not included in a Godot exported project; include filters do not override this boundary. Runtime-required data must not depend on a dot-prefixed path.
- **[MUST]** Verify runtime-required raw data in the actual package. A broad include filter or editor-time readability is not evidence that a dot-prefixed or otherwise filtered path was exported.
- **[REVIEW]** Selected scene/resource export modes must audit dynamic loads, registries, runtime paths, and raw-file dependencies that static dependency traversal may not discover.
- **[MUST]** Do not use broad/murky include/exclude filters merely to shrink or clean the package.

## Dedicated server

- **[MUST]** Treat a dedicated-server preset as a distinct runtime artifact contract, not as a general package-size optimization.
- **[REVIEW]** Dedicated-server export strips or replaces visual Resources with placeholders, including `Material`, `Mesh`, `Texture2D`, `Texture3D`, and `Cubemap`. Audit server runtime dependencies and explicitly keep any Resource whose data is still required.
- **[MUST]** Validate a dedicated-server change with the actual server export plus a defined server startup/smoke path; a normal client export does not prove the server artifact.

## Test/addon isolation

- **[MUST]** Classify addons/resources as test-only, editor-only, or runtime-required before excluding them. `addons/` is not automatically safe to exclude wholesale.
- **[MUST]** Production export excludes test roots, test fixtures, and test-only frameworks/tooling according to project policy.
- **[MUST]** Excluding a file does not remove project/runtime references to it. Validate that production configuration has no dependency on excluded test/editor artifacts.
