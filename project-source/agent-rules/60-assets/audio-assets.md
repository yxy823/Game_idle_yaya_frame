# Audio Assets

Choose codec/import/player mode from clip role, duration, seek/loop behavior, memory, and platform requirements.

## Format and role

- **[MUST]** Distinguish source codec/import encoding from AudioStreamPlayer sample/stream playback mode.
- **[PREFER]** Short high-frequency SFX commonly use WAV/decoded sample paths; long music/voice commonly use compressed streaming such as Ogg, subject to platform/quality needs.
- **[MUST]** Do not transcode one lossy source to another lossy format merely for aesthetic consistency; preserve best source master when available.
- **[REVIEW]** WAV PCM/IMA/QOA choices trade memory, quality, CPU, seek, and loop behavior under the target Godot version; IMA ADPCM is lossy and lower quality, so do not prefer it mechanically.
- **[MUST]** Validate required seek, forward loop, ping-pong, and backward behavior against the actual imported stream and configured player; do not infer codec behavior from historical IMA limitations.

## Import settings

- **[REVIEW]** Force 8-bit is only for intentional low-fidelity/memory goals.
- **[MUST]** Convert to mono only when stereo spatial information is not part of asset.
- **[MUST]** Sample-rate reduction follows source spectrum/pitch/quality requirements.
- **[MUST]** Normalize is content gain adjustment, not a substitute for mixer/bus balancing.
- **[REVIEW]** Trim changes timeline/loop/cue semantics and is not a free cleanup.
- **[MUST]** Loop metadata follows actual codec/import/player semantics and validates loop transition.
- **[MUST]** BPM metadata is only added when interactive music logic actually uses it.
- **[MUST]** File extension does not prove AudioStreamPlayer sample/stream behavior; do not force sample mode merely for WAV or stream mode merely for Ogg/MP3. Validate the configured player/import/platform contract and target export, especially Web.
