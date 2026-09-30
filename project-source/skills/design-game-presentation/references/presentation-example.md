# Example: reward collection with component alternatives

This is an illustrative relationship map, not an approved game design or a document to copy into every project. Paths and choices below are examples; actual documents use verified project locations and `document_language`.

Suppose a player should understand that a claimed reward has reached their inventory. `docs/ui/reward-panel-design.md` owns the panel's layout and claim interaction; `docs/presentation/reward-collection.md` owns the resulting feedback. The UI links the presentation at the claim action and again in its final related-presentations navigation. An inventory screen can link the same presentation with its own target and trigger context.

| Presentation section | Example content |
| --- | --- |
| Goal and observable process | After a successful claim, make the reward's arrival clear. Reference the GDD for when inventory state changes; animation completion does not invent that game rule. |
| Icon flight requirements | Start from the reward's visible position, reach the current screen's inventory indicator, and define what happens if the panel closes or another reward arrives. |
| Icon flight A | A small number of individually controlled icons using property animation; uses the existing item icons by reference. |
| Icon flight B | A denser particle-like visual flow; describe destination tracking, final readability and any texture dependency. Its image format/alpha/display needs and preparation status stay here. |
| Button feedback A / B | A property-based press/release response or a short surface highlight. Keep the common perceptual requirement above the alternatives and the differences inside each alternative. |
| Current use | Reward panel: flight B + button A. Inventory screen: flight A + button A. Only these authorized implementations need work; candidate B for the button may remain a description. |
| Implementation and consumers | Link each adopted component to its actual scene/resource/code or engineering design, and each screen to its real consumer. Mark unavailable implementations as not yet implemented; never invent existing files. |
| Acceptance entry | Link the owning Feature's checks, runnable scenario and existing report/completion record for the specific screen and adopted combination. Do not copy acceptance results into a second table here. |

The development task can implement all three parts together or spread them across existing tasks. If icon flight B is later replaced by A, update that screen's adopted combination and actual consumer links before final verification. Earlier B acceptance evidence remains historical evidence for its recorded version and scope.

Other useful paths:

- **Inventory item added:** start at the UI's item-arrival interaction, follow its presentation link, then its adopted component, actual implementation and acceptance entry.
- **Character death:** start at the GDD's death behavior, follow the presentation and actual death consumer; no UI specification is required just to host the link.
- **Texture still missing:** complete the alternative's behavior and resource specifications, mark the unavailable file, and continue independent planning. It remains a planning result until dependent implementation and actual experience checks become possible.

Extract a component into a shared presentation document only when real reuse makes a separate body useful. The parent then references it; it does not keep another copy of the same requirements or resource specifications.
