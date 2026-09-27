---
name: project-terminology
description: Maintain confirmed project definitions, aliases and links without changing behavior. Use for authorized terminology documentation or a Feature documentation checkpoint; unresolved meanings use project-clarifier and behavior changes use product-author.
---

# Project terminology

Maintain meaning-preserving definitions under `methodology/01-product-doc-structure.md` **Project terminology**. This Skill owns terminology maintenance, including definitions located in GDD; `product-author` maintains game design there and owns any substantive meaning change. Use `methodology/05-document-language.md` for durable wording and the existing project Git rules for writes and commits.

Apply the GDD prerequisite in methodology 01. Read the requested definitions, existing `docs/terminology.md` and only the relevant GDD, Product delivery and code sources. Reuse confirmed decisions and existing documentation authorization; do not repeat an interview. Code shows current behavior and cannot approve a new domain meaning. If a material meaning is undecided, use `project-clarifier`; if the proposed definition changes rules, values, flows or AC, return that decision to `product-author` before editing dependent definitions.

Write the smallest useful definition in its existing owning GDD section, or in `docs/terminology.md` when it is shared across modules or tasks. Keep one definition and repair links within scope, preserving source anchors when moving text. Follow the terminology contract for aliases, retirements and exclusions. A missing Product delivery document or placeholder glossary does not require creating one; an actual GDD is still required. Do not rename code, migrate data, run professional elicitation, create Features or synchronize plans for a meaning-preserving edit.

Check the final wording against confirmed meanings and verify affected links. For a standalone request, commit the validated documentation under the project Git rules unless the user has set a different commit condition; `docs(terminology): <中文术语摘要>` identifies the change without inventing a Feature. Inside an authorized Product or Feature task, return the edited definitions and remaining gaps to its coordinator for the same logical commit and continued work. A supporting call neither starts a new task nor declares its caller complete.
