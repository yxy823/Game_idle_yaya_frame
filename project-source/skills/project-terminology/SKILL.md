---
name: project-terminology
description: "Record confirmed project term definitions, aliases and links in `docs/terminology.md` without changing behavior. Use for authorized terminology documentation, including a Feature's documentation checkpoint. Not for undecided meanings (project-grill-me) or behavior changes (design-gdd)."
---

# Project terminology

Maintain meaning-preserving definitions in the fixed file `docs/terminology.md`, as described in `methodology/14-project-terminology.md`, and maintain the links from documents that use them. `design-gdd` owns substantive game-design meaning, and `design-balance` owns scoped numeric design. Use `methodology/05-document-language.md` for saved wording and the project Git rules for writes and commits.

## Check the inputs

GDD creation may use this Skill for terms whose meanings are already settled; it needs no Product or completed GDD.

Read the requested definitions, the current `docs/terminology.md` and only the relevant idea, GDD, Product delivery and code sources. Reuse confirmed decisions and the current documentation authorization; do not repeat an interview. Code shows current behavior and cannot approve a new domain meaning.

Route decisions this Skill cannot make:

- A material meaning that is still undecided goes to `project-grill-me`.
- A definition that would change game rules, values or flows returns to the GDD design owner before dependent definitions are edited.
- Product delivery changes use `product-author`; changed Feature AC follow the planning workflow.

## Write the definitions

- Write confirmed project definitions only in `docs/terminology.md`, including terms that a single topic uses.
- Move definitions from the authorized scope into that file and replace their old bodies with links, preserving source anchors. `methodology/14-project-terminology.md` covers original-source preservation, aliases, retirements and exclusions; detailed gameplay stays in GDD.
- Target-locale wording belongs to **Term translations** in `docs/localization/localization-spec.md` through `design-localization-spec` (methodology 11 **Localization term translations**). Do not save a target-language glossary as aliases here.
- Create the file when it is missing and confirmed definitions need saving. Without confirmed terms, do not invent entries.

A meaning-preserving edit does not rename code, migrate data, run professional clarification, create Product delivery documents or Features, or synchronize plans.

## Validate and commit

Check the final wording against confirmed meanings and verify affected links. For a standalone request, commit the validated documentation under the project Git rules unless the user has set a different commit condition. Use `docs(terminology): <中文术语摘要>`; no Feature is invented.

Inside an authorized Product or Feature task, return the edited definitions and remaining gaps to its coordinator for the same logical commit.

Return to the caller; a Skill's return does not end its authorized task (methodology 03 **Authorization and continuation**).
