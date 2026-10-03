---
name: design-audio-asset-spec
description: "Specify concrete sound effects, music and ambience, including sample references and listening needs, in their owning resource sections. Use for audio file specifications. Not for shared sound direction, production, integration or audio review."
---

# Audio asset specification

Follow `methodology/11-specialist-workflows.md` for ownership, authorization, source impacts and finalization. Its **Resource requirements and handoff** section selects the owning section (a presentation, UI or extracted component section, or **Shared resource specifications** in `docs/audio/sound-bible.md`), lists the common resource fields and explains how specifications move when the owner changes. Do not create a separate preparation list. Write in `document_language`.

Read confirmed GDD triggers, Product delivery scope, the applicable Sound Bible, related entries and actual sample references. Detailed shared sound standards belong to `design-audio-direction`. Reference GDD-owned direction, triggers and values instead of copying them. Reuse settled decisions and clarify only material gaps. Do not add a cue to every interaction or assume voice-over. An unknown value may stay pending while other useful specification work continues.

## Concrete deliverables

| Kind | Useful specification |
| --- | --- |
| SFX | Exact trigger and conditions; feedback purpose; duration or range; shared style or an explicit exception; repetition, overlap and priority needs; available references and qualities to avoid |
| Music or ambience | Use scenario and transitions; mood, texture and rhythm; duration and loop behavior; relevant relative mix and priority expectations; references and qualities to avoid |

Keep the intended production trigger separate from a prototype's preview button. Do not present oscillator settings, loudness numbers or sample rates as confirmed requirements; record technical constraints only when needed or actually measured. Pixel dimensions do not apply to audio.

Preserve local resource IDs and real filenames. In the owning resource section, record the source or actual location, target path, observed duration and format, preparation status and whether the file is a sample or final.

An unresolved slot may use the example names `_placeholder_sfx_<action>.wav` or `_placeholder_bgm_<name>.ogg` when those formats fit. Such a name creates no file, fixes no format and does not require renaming an available sample. Mark suggestions as suggestions; a candidate alternative's dependency is not automatically a file to prepare.

## Handoff and boundaries

Provide available playable samples, missing files and applicable checks, such as feedback timing, masking or loop continuity, to the authorized Godot prototype or delivery task. A missing reference need not block drafting, but actual listening evaluation stays unverified. A textual description or silence is not evidence.

Music and SFX production are reserved capabilities with no Skill (methodology 11 **Design, production, integration and review**). This Skill does not synthesize, record, acquire or process files. `content-asset-integration` connects supplied audio, and `review-audio` evaluates it in a separate instance. Do not claim production, playback or acceptance without the corresponding action and evidence.

Return specification paths, resource IDs, decisions and gaps. Behavior changes go to `design-gdd`; changed professional requirements use the change routes under **Writing and adoption** in methodology 11.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
