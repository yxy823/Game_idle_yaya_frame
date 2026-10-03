# 13 · Prototypes

`prototype-godot` builds bounded Godot prototypes. This specification covers two kinds:

- [Visual prototype before dependent implementation](#visual-prototype-before-dependent-implementation): settle layout, resource scale and interaction readability before logic that depends on them.
- [Scoped logic prototypes](#scoped-logic-prototypes): answer a specific interaction, state-transition or technical-feasibility question.

A prototype runs inside a planned Feature or an authorized experiment; [task routing](00-overview.md#canonical-task-routing) selects the entry. Prototype observations and tentative parameters are not approved GDD design or Feature acceptance. Stay within the agreed experiment budget; going beyond it requires the user's direction.

## Visual prototype before dependent implementation

A new interface, or a substantial change to an interface's layout or resources, needs a validated visual foundation before logic that depends on that interface is implemented.

- Reuse an already validated layout when it covers the current scope.
- Text or value changes, non-visual logic and unaffected modules do not need another prototype.
- Work on the current interface or module in its surrounding screen context. Do not wait until all game art or all future screens are ready.

Follow this sequence:

1. Define the interface's purpose and main states.
2. Collect representative resources and write initial specifications.
3. Build an independent Godot visual prototype.
4. Validate and adjust layout and scale.
5. Implement the dependent production logic.
6. Refine the visuals.

Resource specifications and layout may iterate together.

The Agent identifies the need for a visual prototype during planning and the Stage 1 resource preflight, or the user requests one directly. This is task reasoning, not a background trigger. Discussion-only work proposes the next step without writing files or building scenes. Implementation authorization covers in-scope preparation and building, but it never supplies the user's visual acceptance.

### Scope and resources

Before building, identify:

- the questions the prototype must settle;
- the target viewport or window and the relevant scaling conditions;
- the core elements and states;
- the available resources and the remaining gaps.

The UI, presentation and asset specification Skills under [Specialist work and sources](11-specialist-workflows.md) specify these inputs. A written sketch or an HTML exploration does not verify the Godot result. When resources must be prepared or supplied first, use [Resource requirements and handoff](11-specialist-workflows.md#resource-requirements-and-handoff).

Use representative real images, fonts, video, music and sound effects where the interface calls for them:

- Choose samples that expose the actual aspect ratios, detail, text lengths and content density. Not every media type or the complete asset library is needed.
- Distinguish the source pixel dimensions, the on-screen size and the visible subject size after transparent padding.
- For audio, identify the duration, looping and feedback timing that matter to the experience.
- Follow the project's asset provenance and import rules.
- A missing sample leaves its check unverified. Name the gap and find a suitable sample or a substitute the user accepts. Text, silence or a placeholder filename does not prove the check.

Build the prototype as follows:

- Create a clearly named, independently runnable `.tscn` in the project's scene organization, separate from production functionality.
- Include the actual content regions, representative items, buttons and text in their surrounding layout.
- Use local sample state. Add only the interactions needed for evaluation, such as hover, pressed, selected and disabled feedback, opening a panel, scrolling or preview playback.
- Do not connect production game rules, persistence or live data flows. If project Autoloads would run those flows, isolate the prototype entry from their side effects.
- A small local script is enough when native controls cannot express the required feedback.

Final backgrounds, decoration and palette are optional at this point. Readable contrast and distinguishable interaction states are required for evaluation. There is no fixed number of design variants; compare alternatives only when a real layout decision needs them.

### Validation and adoption

Run the scene in the target project's confirmed Godot environment. At the agreed display conditions, check spatial relationships, resource scale and cropping, text readability, button usability and the relevant empty, dense and long-text states. Exercise the interactions and listen to the relevant samples. Static checks and screenshots support the evaluation; they do not replace actual operation and human judgment. Missing execution or human feedback stays explicitly unverified.

Record the results:

- Keep the entry scene, questions, observations, file disposition and links to the relevant presentation and resource sections in the current Feature notes, or in Progress for a standalone experiment.
- Keep resource details in the design document that uses the resource.
- Send each confirmed change to its source: game design to the GDD through `design-gdd` (or `design-balance` for scoped numerical design), delivery boundaries to Product, and layout, presentation, size, readability or sound specifications to their specialist document. Adoption follows the task's authorization and the source-change routes in [Specialist work and sources](11-specialist-workflows.md#ownership-and-decisions).
- Node properties and tuning values stay in the scene, resources or implementation notes.
- Do not maintain a second specification or a prototype status ledger.

During planned delivery, use an ordinary Feature for a visual foundation that can be reviewed on its own, and make dependent implementation wait for its manual acceptance when that Feature requires it. A narrow check may stay inside the current Feature, as long as the visual decision is settled before dependent logic. A standalone exploration the user explicitly requested follows the scoped-experiment route in [task routing](00-overview.md#canonical-task-routing). Prototype acceptance covers only its visual and interaction scope, never the later business behavior.

After validation, reuse suitable layout nodes, themes and resources deliberately, and remove the sample-state wiring when adopting them into production. Keep a separate prototype only while it answers an open question; otherwise archive or remove it within the authorized scope. Record unresolved limits and keep the accepted decisions. Do not maintain competing production and prototype interfaces.

## Scoped logic prototypes

Use `prototype-godot` when an authorized experiment can settle a specific interaction, state-transition or technical-feasibility question. Before building, identify:

- the question;
- the relevant confirmed GDD rules;
- the observed result that would answer the question;
- the bounded experiment.

Keep unsettled design choices as proposals; an experiment does not approve a new rule. Reuse a previous experiment when it still answers the question, and follow the scoped-experiment route in [task routing](00-overview.md#canonical-task-routing).

Prefer a small, independently runnable Godot scene with only the state and interactions the question needs:

- Make the relevant state visible.
- Support resetting to a known starting point.
- Combine free operation with repeatable situations that expose the uncertainty. For a crafting queue, useful situations might include insufficient materials, pausing, or cancellation and refund. Include only the situations relevant to the confirmed question; there is no required number of cases or visual variants.

Local sample state is suitable for exploring a proposed interaction. If the question concerns actual signals, input, lifecycle, persistence or another engine integration, exercise the real path under the task's permissions and protect live data. A simulated transition cannot prove that an integration works. When judging layout, representative assets or perceptual quality, apply the [visual prototype requirements](#visual-prototype-before-dependent-implementation) as well. HTML is acceptable only for an explicitly requested engine-independent concept demonstration; it is not a required precursor or evidence of Godot behavior.

Report what the experiment answered, the actual observations and the remaining limits. Record and adopt results under [Validation and adoption](#validation-and-adoption): keep the entry and useful evidence in Feature notes or Progress, return accepted decisions to their source documents, and decide what happens to the sample code within the authorization. A successful experiment does not establish production readiness, required regression coverage or human acceptance. Do not make an experiment a prerequisite for work that has no relevant uncertainty.
