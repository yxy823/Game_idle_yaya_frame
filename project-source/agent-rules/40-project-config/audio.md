# Audio Project Configuration

Audio bus identity and driver/mix settings are project/runtime contracts.

## Audio

- **[MUST]** Configured default bus layout path is a project Resource dependency and must resolve/load.
- **[MUST]** Audio bus names are cross-file APIs. Rename/remove migrates AudioStreamPlayers, code, animation, and mixer consumers.
- **[MUST]** Do not assume a missing old bus will fail loudly; fallback to Master can silently mask migration errors.
- **[MUST]** Configured driver/mix rate/latency is not necessarily actual runtime device state. Validate platform/runtime where relevant.
