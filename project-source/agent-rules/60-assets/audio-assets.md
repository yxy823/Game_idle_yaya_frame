# Audio Assets

Choose the codec, import settings and player mode from the clip's role, duration, seek and loop behavior, memory and platform requirements.

## Format and role

- **[MUST]** Distinguish the source codec and import encoding from the sample or stream playback mode of the AudioStreamPlayer.
- **[PREFER]** Short, frequent sound effects commonly use WAV or decoded sample paths; long music and voice commonly use compressed streaming such as Ogg, subject to platform and quality needs.
- **[MUST]** Do not transcode one lossy source to another lossy format merely for consistency; preserve the best source master when one is available.
- **[REVIEW]** WAV PCM, IMA ADPCM and QOA trade memory, quality, CPU cost, seeking and loop behavior differently in the target Godot version. IMA ADPCM is lossy and lower in quality, so do not prefer it mechanically.
- **[MUST]** Validate the required seek, forward loop, ping-pong and backward behavior against the actual imported stream and configured player. Do not infer codec behavior from limitations that IMA ADPCM had in earlier Godot versions.

## Import settings

- **[REVIEW]** Use Force 8-bit only for intentional low-fidelity or memory goals.
- **[MUST]** Convert to mono only when stereo spatial information is not part of the asset.
- **[MUST]** Reduce the sample rate only as far as the source spectrum, pitch and quality requirements allow.
- **[MUST]** Normalize adjusts the content's gain; it is not a substitute for balancing in the mixer or buses.
- **[REVIEW]** Trimming changes timeline, loop and cue semantics and is not free cleanup.
- **[MUST]** Loop metadata follows the actual codec, import and player semantics, and the loop transition is validated.
- **[MUST]** Add BPM metadata only when interactive music logic actually uses it.
- **[MUST]** The file extension does not prove sample or stream behavior. Do not force sample mode merely because a file is WAV, or stream mode merely because it is Ogg or MP3. Validate the configured player, import and platform contract and the target export, especially for the Web.
