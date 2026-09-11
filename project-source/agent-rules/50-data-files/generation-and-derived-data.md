# Generated and Derived Data

Separate parser, validator, normalizer, and generator responsibilities and keep generated output reproducible.

## Pipeline

- **[MUST]** Generators consume validated normalized input, not partially invalid raw structures.
- **[MUST]** Input discovery is explicit; do not sweep arbitrary directories and accidentally ingest temp/vendor/unrelated files.
- **[MUST]** Derived fields are recomputed from authoritative inputs. If materialized for runtime performance, they remain generated and are not hand-edited.
- **[MUST]** Write canonical output to temp, validate completeness, then atomically replace committed/runtime artifact so failure cannot leave partially written or stale-success state.

## Version-control policy

- **[MUST]** If generated artifacts are committed, regeneration-check must match committed output and generated artifact is not hand-edited.
- **[MUST]** If generated artifacts are not committed, a clean checkout can fully regenerate them from declared dependencies.
- **[MUST]** A source-file hash can detect stale bytes but is not a semantic hash or schema version.
- **[MUST]** Repeat-generation determinism is a validation target for generator/normalizer changes.
