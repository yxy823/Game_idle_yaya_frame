# Localization Project Configuration

Translation resources must be registered and locale/fallback semantics explicit.

## Localization

- **[MUST]** A translation file existing in the project does not mean it is registered for runtime localization.
- **[MUST]** Define fallback locale deliberately; do not accidentally rely on English or editor locale.
- **[MUST]** Use locale identifiers supported by target Godot version and project localization contract.
- **[MUST]** Locale test overrides are temporary test/runtime state, not persistent production project configuration.
- **[MUST]** `internationalization/locale/test` also affects exported projects; isolate Editor-only locale tests with an appropriate `editor` feature override or other test configuration so the test locale does not enter production exports.
- **[MUST]** Translation remaps create source+locale dependency contracts and must be migrated together.
- **[PREFER]** Use pseudolocalization as a validation tool where UI localization coverage matters.
