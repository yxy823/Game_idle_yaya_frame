---
name: product-ui-sketcher
description: Turns Product behavior and interaction details into an ASCII wireframe and intent explanation, with an optional standalone HTML and Tailwind visual exploration.
metadata:
  version: 2.0
  triggers:
    - Sketch a Product UI, ASCII wireframe, or optional HTML mockup
    - 用户要求「UI 线框」「ASCII 界面」或「HTML mockup」
  priority: medium
  called_by: product-change-standardizer
---

# Product UI sketcher

## Role

Create a Product-blueprint wireframe, not a final visual design. Show where elements are and what interactions do. Do not lock implementation into specific colors, fonts, animation, pixels, or framework choices.

The durable Product artifact is the ASCII wireframe plus its intent and interaction notes. An HTML and Tailwind exploration is optional and independently replaceable.

## Language contract

Apply `methodology/05-document-language.md` to wireframe labels, interaction
notes and returned HTML prose. Reuse confirmed `document_language` from the
caller or resolve it from project configuration. Set optional HTML `lang` to
that BCP 47 value; ASCII/interaction syntax and protocol keys remain stable.

## Core principles

1. **ASCII is the durable source.** The Product module always receives the ASCII representation.
2. **HTML is opt-in.** Generate it only when `want_html_mockup: true` has been explicitly confirmed.
3. **Intent is mandatory.** Explain why the layout supports Product behavior.
4. **Do not prescribe colors, fonts, animation, pixel dimensions, or spacing in Product prose.** Those belong to implementation or later visual refinement.
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
5. **Visual exploration:** include the optional HTML path only when generated.

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

### <Visual exploration>

<localized reference to `docs/ui-mockups/timer-core.html`>
````

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
  implementation constraints: docs/coding_rules.md
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
