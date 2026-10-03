# Export Secrets and Signing

Keep shareable preset metadata separate from credentials and release secrets.

## Secrets

- **[MUST]** Do not commit export passwords, encryption keys, private keys, access tokens or other secrets into `export_presets.cfg`, tests, AGENTS files, ordinary project configuration or logs.
- **[MUST]** Use Godot credential storage, supported environment variables or approved CI secret storage for sensitive export credentials.
- **[MUST]** Classify fields by their actual confidentiality. Package and bundle IDs and certificate names are not automatically secrets, while passwords and private keys are.
- **[MUST]** Do not print complete secret values in build or test diagnostics.

## Signing

- **[MUST]** If production signing or notarization credentials are unavailable, report the Release gate as blocked.
- **[MUST]** Do not obtain a green Release export by silently disabling signing or notarization, switching to debug signing or using ad-hoc credentials, unless the task explicitly targets that mode.
