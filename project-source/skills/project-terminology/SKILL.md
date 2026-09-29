---
name: project-terminology
description: Maintain confirmed project definitions, aliases and links without changing behavior. Use for authorized terminology documentation or a Feature documentation checkpoint; unresolved meanings use project-grill-me and behavior changes use design-gdd.
---

# Project terminology

Maintain meaning-preserving definitions under `methodology/01-product-doc-structure.md` **Project terminology**. This Skill owns terminology maintenance, including definitions located in GDD; `design-gdd` owns substantive game-design meaning, and `design-balance` owns scoped numeric design. Use `methodology/05-document-language.md` for durable wording and the existing project Git rules for writes and commits.

Apply the creation or development prerequisites in methodology 01 to the actual task. GDD creation may use this method for useful terms whose meanings are already settled; it does not need a pre-existing Product or a completed GDD. Read the requested definitions, existing `docs/terminology.md` and only the relevant idea/GDD, Product delivery and code sources. Reuse confirmed decisions and existing documentation authorization; do not repeat an interview. Code shows current behavior and cannot approve a new domain meaning. If a material meaning is undecided, use `project-grill-me`; if the proposed definition changes game rules, values or flows, return it to the GDD design owner before editing dependent definitions. Product delivery changes use `product-author`, and changed Feature AC follow the existing planning contract.

Write the smallest useful definition in its owning GDD section, or in `docs/terminology.md` when it is shared across modules or tasks. Keep one definition and repair links within scope, preserving source anchors when moving text. Follow the terminology contract for aliases, retirements and exclusions. Do not create a Product delivery document or a glossary merely to complete this method. Do not rename code, migrate data, run professional elicitation, create Features or synchronize plans for a meaning-preserving edit.

Check the final wording against confirmed meanings and verify affected links. For a standalone request, commit the validated documentation under the project Git rules unless the user has set a different commit condition; `docs(terminology): <中文术语摘要>` identifies the change without inventing a Feature. Inside an authorized Product or Feature task, return the edited definitions and remaining gaps to its coordinator for the same logical commit and continued work. A supporting call neither starts a new task nor declares its caller complete.
