---
name: design-audio-asset-spec
description: Specify concrete sound effects, music and ambience, including sample references and listening needs. Maintains resource specifications; excludes shared sound direction, production, integration and audio review.
metadata:
  version: 2.0
  priority: medium
---

# Audio asset specification

Use `methodology/11-specialist-workflows.md` for ownership, authorization, source impacts and finalization. Maintain audio requirements inside the owning presentation alternative, interface document or shared sound design section under **Resource requirements and handoff** in `methodology/01-product-doc-structure.md`. Expand complex resource details there and reference shared requirements once; do not create a separate preparation list. Follow `document_language`.

Read confirmed GDD triggers and Product delivery scope, applicable Sound Bible, related entries and actual sample references. Use `design-audio-direction` for detailed shared sound standards. Reference GDD-owned direction, triggers and values rather than copying them into another source. Reuse settled decisions, and clarify only material gaps. Do not add a cue to every interaction or assume voice-over. An unknown value may remain pending while other useful specification work continues.

## Concrete deliverables

| Kind | Useful specification |
| --- | --- |
| SFX | Exact trigger and conditions; feedback purpose; duration/range; shared style or explicit exception; repetition/overlap/priority needs; available references and qualities to avoid |
| Music / ambience | Use scenario and transitions; mood/texture/rhythm; duration and loop behavior; relevant relative mix/priority expectations; references and qualities to avoid |

Keep the intended production trigger distinct from a prototype's preview button. Do not invent oscillator settings, loudness numbers or sample rates as if they were confirmed requirements. Record technical constraints only when needed or actually measured. Pixel dimensions are not applicable to audio.

Preserve local resource IDs and real filenames. Record source/actual location, target path, observed duration/format, preparation status and sample/final status in the owning resource section. An unresolved slot may use the existing examples `_placeholder_sfx_<action>.wav` or `_placeholder_bgm_<name>.ogg` when those formats are appropriate. This does not create a file, force a format decision or require renaming an available sample. Mark suggestions as suggestions; a candidate alternative's dependency is not automatically a file to prepare.

## Handoff and boundaries

Provide available playable samples, missing files and applicable checks such as feedback timing, masking or loop continuity for the authorized Godot prototype or delivery task. A missing reference need not block drafting; it leaves actual listening evaluation unverified. A textual description or silence is not evidence.

Music and SFX production are reserved capabilities. This Skill does not synthesize, record, acquire or process files. `content-asset-integration` connects supplied audio; `review-audio` evaluates it in a separate instance. No production, playback or acceptance may be claimed without the corresponding actual action/evidence.

Return specification paths/resource IDs, decisions and gaps. Route behavior changes to `design-gdd` for GDD maintenance, and changed professional requirements through the existing planning impact route. Continue the caller's authorized work without creating a second delivery process.
