# Generated and Derived Data

Separate the responsibilities of parser, validator, normalizer and generator, and keep generated output reproducible.

## Pipeline

- **[MUST]** Generators consume validated, normalized input, not partially invalid raw structures.
- **[MUST]** Input discovery is explicit. Do not sweep arbitrary directories and accidentally ingest temporary, vendor or unrelated files.
- **[MUST]** Derived fields are recomputed from authoritative inputs. If they are materialized for runtime performance, they remain generated and are not hand-edited.
- **[MUST]** Write canonical output to a temporary location, validate its completeness, then atomically replace the committed or runtime artifact, so that a failure cannot leave a partially written or stale "successful" state.

## Version-control policy

- **[MUST]** If generated artifacts are committed, a regeneration check matches the committed output, and the generated artifact is not hand-edited.
- **[MUST]** If generated artifacts are not committed, a clean checkout can fully regenerate them from the declared dependencies.
- **[MUST]** A source-file hash can detect stale bytes, but it is not a semantic hash or a schema version.
- **[MUST]** Repeat-generation determinism is a validation target for generator and normalizer changes.
