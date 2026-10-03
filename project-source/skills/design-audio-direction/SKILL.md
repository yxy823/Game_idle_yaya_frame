---
name: design-audio-direction
description: "Define or revise shared music, ambience and sound-effect direction and feedback priorities in the Sound Bible. Use for shared sound standards. Not for concrete audio specifications (design-audio-asset-spec), asset production or audio review (review-audio)."
---

# Sound direction (Sound Bible)

Follow `methodology/11-specialist-workflows.md` for ownership, authorization and source impacts. **What stays in the GDD** in that file covers moving sound specifications out of GDD. Read the relevant GDD experience goals, feedback behavior, current audio conventions and available references.

## Maintain the Sound Bible

Keep shared sound specifications only in `docs/audio/sound-bible.md`. They cover:

- sonic identity serving the GDD's experience goals;
- the roles of music, ambience and effects;
- the importance and coexistence of feedback;
- transitions, repetition fatigue and silence;
- accessibility needs, such as whether essential information also has a visual channel.

GDD keeps intended player feelings, recognition needs and gameplay feedback triggers, and links this specification. Scope each rule to its applicable scenes or sound families.

Describe useful timbre, texture, rhythm and dynamics in terms that can guide a concrete specification. Do not invent loudness targets, sample rates, technical bus topology or a complete soundtrack when they are not requirements. Changes to adopted game-design intent or behavior return to GDD through `design-gdd`; mixing implementation belongs to the authorized implementation task.

References establish direction only. Written descriptions are not listening evidence, and no generated examples are promised. Music and SFX production are reserved capabilities with no Skill (methodology 11 **Design, production, integration and review**).

## Hand off

- Concrete deliverables go to `design-audio-asset-spec`. When **Resource requirements and handoff** in `methodology/11-specialist-workflows.md` selects the Sound Bible, that Skill maintains the Bible's **Shared resource specifications** section; this Skill keeps the direction standards those entries reference. Do not create a second soundtrack or receiving catalog.
- Supplied files go to `content-asset-integration`.
- Formal evaluation uses `review-audio` in a different instance.

Report the confirmed direction, applicable sources and gaps.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
