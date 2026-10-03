---
name: content-asset-integration
description: "Import, replace or connect available game assets in an authorized Godot task. Use for supplied or reused files whose specifications already exist. Not for asset creation or independent asset auditing."
---

# Asset integration

Follow `methodology/11-specialist-workflows.md` for scope and ownership. Runtime changes belong to the current authorized Feature or scoped experiment; return there for validation and completion.

## Read the requirements and the files

- Read the affected resource sections in the owning presentation alternative, UI specification or shared design section, located under **Resource requirements and handoff** in `methodology/11-specialist-workflows.md`. Also read the currently adopted approach and the actual source files.
- Read the relevant `agent-rules/60-assets/` rules, resource-reference rules and scene and resource rules.
- Confirm provenance and usage constraints from available records. Unknown provenance is a gap; do not make up a license.
- Inspect the actual type, dimensions, transparency, duration, channels or animation properties as applicable.

## Integrate

Map each reused or supplied file to its project destination and consumers. Preserve external originals, unrelated resources and valid UID and path relationships. Choose import settings for the actual use and target constraints; do not blindly reimport the full library. Update affected scenes, themes, resource bindings or audio routing without redesigning the approved requirement.

## Verify and record

Verify import and, where needed, actual in-context rendering, playback or animation. File presence, successful import, measured fit and human acceptance are separate facts.

Before final task verification, update the preparation status and the actual resource and consumer paths in their owning sections, including the presentation's adopted combination when affected. Keep missing files and unverifiable experience checks explicit. Acceptance results stay in the linked report or completion record.

Asset production is a reserved capability with no Skill (methodology 11 **Design, production, integration and review**). Formal technical inspection uses `review-assets` in a separate instance, with `review-art` or `review-audio` for the experience.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
