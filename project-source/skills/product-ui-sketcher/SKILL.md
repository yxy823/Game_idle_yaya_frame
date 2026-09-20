---
name: product-ui-sketcher
description: Clarify Product UI layout, interactions and visual specifications, including inputs for a Godot visual prototype. Produces requirement drafts, not runnable Godot scenes.
metadata:
  version: 2.1
  triggers:
    - Sketch a Product UI or clarify visual specifications and prototype inputs
    - 用户要求界面线框、视觉基础规格或可选 HTML 探索
  priority: medium
  called_by: product-standardizer
---

# Product UI sketcher

## Role

Create a Product-blueprint wireframe and the visual requirements needed to evaluate it. Show where elements are, what interactions do and which layout/resource questions still need a running Godot scene. Preserve confirmed size, typography and readability constraints without inventing final art direction or node-level implementation choices.

The durable Product artifact is the ASCII wireframe plus its intent, interaction notes and confirmed visual requirements. An HTML and Tailwind exploration is optional and independently replaceable; it cannot replace the Godot visual prototype defined in `methodology/01-product-doc-structure.md` under **Visual prototype before dependent implementation**.

## Language contract

Apply `methodology/05-document-language.md` to wireframe labels, interaction
notes and returned HTML prose. Reuse confirmed `document_language` from the
caller or resolve it from project configuration. Set optional HTML `lang` to
that BCP 47 value; ASCII/interaction syntax and protocol keys remain stable.

## Core principles

1. **ASCII is the durable source.** The Product module always receives the ASCII representation.
2. **HTML is opt-in.** Generate it only when `want_html_mockup: true` has been explicitly confirmed.
3. **Intent is mandatory.** Explain why the layout supports Product behavior.
4. **Separate requirements from tuning.** Record confirmed display conditions, resource proportions, text/button usability and necessary size constraints. Mark trial values as proposals; keep node properties and incidental tuning in implementation, and leave final decoration/palette open unless already decided.
5. **Mark every interactive element.** Use the fixed syntax below.

## Input

```yaml
document_language: en
module_name: timer-core
context: <Product behavior in document_language>
interactive_elements:
  - name: <label in document_language>
    behavior: <observable result in document_language>
display_elements:
  - <display requirement in document_language>
intent: <Product intent in document_language>
want_html_mockup: false
visual_tone: <Product-wide visual direction in document_language>
```

`module_name`, paths, keys, and Boolean values stay stable. Human-readable values follow `document_language`.

## Fixed ASCII conventions

Use these meanings consistently across the project:

| Element | Stable representation |
| --- | --- |
| Container | `┌─┐ │ │ └─┘` or emphasized `┏━┓ ┃ ┃ ┗━┛` |
| Divider | horizontal `├─┤` or vertical `│` |
| Text | render the actual Product label in `document_language` |
| Button | `[label]` |
| Primary CTA | `[[label]]` |
| Input | `< placeholder >` |
| Select | `[option ▾]` |
| Checkbox | `[ ]` or `[x]` |
| Radio | `( )` or `(•)` |
| Slider | `─────●────────` |
| Progress | `━━━━━━━━━━░░░░░░` |
| Image or icon | `[image: description]` or `[icon: description]`, localized naturally |
| Scroll area | add `↕` to the right edge |
| Collapsible area | `▸ label` or `▾ label` |
| List item | `• content` |
| Data value | use a realistic example such as `25:00`, not a token such as `MM:SS` |

Only one `[[primary CTA]]` may appear in one interface state.

## Required Product output

Return content that the standardizer can place in the module's UI section. Its localized headings must preserve these semantics:

1. **Primary layout:** one ASCII wireframe.
2. **Interaction details:** a table mapping each element and condition to observable behavior.
3. **Intent:** why hierarchy, grouping, and feedback support the Product goal.
4. **State differences:** list meaningful differences rather than drawing every state, unless layouts differ substantially.
5. **Visual foundation:** relevant display conditions, representative resource references, confirmed constraints and unresolved prototype questions. Reuse existing decisions; do not invent measurements or claim a sketch proves runtime readability.
6. **Visual exploration:** include the optional HTML path only when generated.

Example structure, with labels rendered in `document_language`:

````markdown
### <Primary layout>

```
┌──────────────────────────────────────┐
│          [image: companion]          │
│                25:00                 │
│       ━━━━━━━━━━━━━━━━━━━━           │
│          [[Start]]  [Settings]       │
│          Sessions today: 3           │
└──────────────────────────────────────┘
```

### <Interaction details>

| <Element> | <Condition> | <Behavior> |
| --- | --- | --- |
| `[[Start]]` | <user activates> | <start countdown and show Pause> |

### <Intent>

- <reason for visual hierarchy in document_language>

### <State differences>

- `idle`: <difference in document_language>
- `running`: <difference in document_language>
- `paused`: <difference in document_language>
- `completed`: <difference in document_language>

### <Visual foundation>

<confirmed display constraints, available samples and questions for Godot validation>

### <Visual exploration>

<localized reference to `docs/ui-mockups/timer-core.html`>
````

## Handoff to the Godot visual prototype

When the visual-prototype criteria in `methodology/01-product-doc-structure.md`
apply, return the relevant inputs in the UI Markdown and `notes_for_standardizer`:
surrounding screen layout, representative content/states, available image/font/video
references and missing samples, plus the decisions that need actual operation.
When a preparation list is requested or needed for a resource handoff, follow
**Resource preparation list and handoff** in the same specification. Return UI
resource contributions through the existing notes, with confirmed/proposed sizes
distinguished; the caller merges them with other resource types into one list.
Use `product-audio-sketcher` through the caller only when sound requirements also
need clarification. Do not require a fresh sketch or interview for settled inputs.

The standardizer owns approved Product writes and planning; authorized scene
implementation uses the existing delivery or scoped-experiment route. This Skill
does not create `.tscn` files, connect business logic or grant human acceptance.
After a prototype, reuse its actual observations and user decisions to propose
focused updates to the same UI requirements rather than treating trial values as
automatically approved specifications.

## Optional HTML and Tailwind exploration

Run this section only when `want_html_mockup: true`.

- Path: `docs/ui-mockups/{module-name}.html`, without a numeric prefix.
- Put all primary states in one file rather than creating one file per state.
- Translate the ASCII structure into static semantic HTML; avoid JavaScript unless native HTML such as `<details>` cannot express the exploration.
- Use Tailwind only to express the confirmed `visual_tone`. It is exploratory, not a final engine or framework implementation.
- Keep visible labels and explanatory comments in `document_language`.
- Set `<html lang="<document_language>">` and `<meta charset="UTF-8">`.
- Produce a complete standalone HTML document with `<!DOCTYPE html>`, `<head>`, `<body>`, a localized `<title>`, and an explicit Tailwind loading mechanism such as `<script src="https://cdn.tailwindcss.com"></script>`.

The file must begin with a localized comment preserving these meanings:

```html
<!--
  This is a replaceable visual exploration, not the final implementation.
  Product intent: docs/product/NN-xxx.md
  implementation constraints: docs/project-rules.md
  Replacing this file does not change the Product blueprint.
-->
```

Possible tone mappings are implementation examples for the mockup only:

- warm: `bg-stone-*` or `bg-amber-*`
- minimal and cool: `bg-slate-*` or `bg-neutral-*`
- retro pixel: `font-mono` and high contrast
- cyberpunk: `bg-zinc-900` with restrained neon accents

## Return structure

```yaml
ascii_wireframe: |
  <localized Markdown ready for the Product UI section>

html_mockup:
  generated: true | false
  path: docs/ui-mockups/timer-core.html
  content: |
    <complete HTML when generated>

notes_for_standardizer:
  - <localized note about related Product data, UI, or audio changes>
```

When `generated` is `false`, omit `path` and `content`. `notes_for_standardizer` may request another Product workflow, but this sketcher does not edit Product files or call it directly.
