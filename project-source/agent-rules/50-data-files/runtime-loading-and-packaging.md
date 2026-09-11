# Runtime Loading and Packaging

Editor visibility does not prove raw runtime data is inside the exported package.

## Runtime data

- **[MUST]** Raw `res://` JSON/CSV/TXT loaded through FileAccess has an explicit export inclusion policy under `41-export-config`.
- **[PREFER]** When appropriate, convert canonical data to `.tres`/custom Resource/binary and load via ResourceLoader instead of maintaining a raw-file runtime path.
- **[MUST]** Project-embedded raw data and external `user://`/mod data are separate trust/packaging domains.
- **[MUST]** Final validation for raw runtime data includes actual exported-build/PCK availability and production load/consumer behavior.

## Trust boundary

- **[MUST]** Project-authored trusted data and player/mod/network/external untrusted data have separate trust policies.
- **[MUST]** Untrusted data has explicit size/depth/shape/schema constraints where denial-of-service or pathological input is plausible.
