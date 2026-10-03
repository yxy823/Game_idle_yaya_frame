# Example: item arrival with component alternatives

This is an illustrative relationship map, not an approved game design or a document to copy into every project. Paths and choices below are examples; actual documents use verified project locations and `document_language`.

Suppose a player should understand that an item has reached their inventory, whether from a reward claim or a shop purchase. `docs/ui/reward-panel-design.md` owns an independently opened reward overlay's layout and claim interaction; a panel embedded in another screen would instead be a section of that host. `docs/presentation/item-added.md` owns the shared item-arrival moment. Reward and shop UI documents link it at their use sites and in their final related-presentations navigation, retaining their own origin, target and trigger context.

| Presentation section | Example content |
| --- | --- |
| Goal and observable process | After a confirmed item addition, make its arrival clear. Reference the GDD for when inventory state changes; animation completion does not invent that game rule. |
| Icon flight requirements | Start from the source's visible position, reach the current screen's inventory indicator, and define what happens if the screen closes or another item arrives. |
| Icon flight A | A small number of individually controlled icons using property animation; item icons also used by inventory/shop link the Art Bible's shared-resource section. |
| Icon flight B | A denser particle-like visual flow; describe destination tracking, final readability and any texture dependency. Its image format/alpha/display needs and preparation status stay here. |
| Destination feedback A / B | A short scale pulse or surface highlight on the receiving inventory indicator. Keep the common perceptual requirement above the alternatives and the differences inside each alternative. Ordinary button press/release behavior stays in the UI specification. |
| Current use | Reward overlay: flight B + destination A. Shop: flight A + destination A. Only these authorized implementations need work; candidate B for the destination may remain a description. |
| Implementation and consumers | Link each adopted component to its actual scene/resource/code or engineering design, and each screen to its real consumer. Mark unavailable implementations as not yet implemented; never invent existing files. |
| Acceptance entry | Link the owning Feature's checks, runnable scenario and existing report/completion record for the specific screen and adopted combination. Do not copy acceptance results into a second table here. |

The development task can implement the parts together or spread them across existing tasks. If icon flight B is later replaced by A, update that screen's adopted combination and actual consumer links before final verification. Earlier B acceptance evidence remains historical evidence for its recorded version and scope.

Other useful paths:

- **Inventory item added:** start at the UI's item-arrival interaction, follow its presentation link, then its adopted component, actual implementation and acceptance entry.
- **Character death:** start at the GDD's death behavior, follow the presentation and actual death consumer; no UI specification is required just to host the link.
- **Texture still missing:** complete the alternative's behavior and resource specifications, mark the unavailable file, and continue independent planning. It remains a planning result until dependent implementation and actual experience checks become possible.

Reward and shop are two consumers of the same `item-added.md` moment, so they do not trigger component extraction. A separate reward-reveal process may show an unknown reward before acceptance; if it ends with item arrival, it links `item-added.md` for that part.

If a distinct `item-offered.md` presentation communicates a confirmed item removal into an offering receptacle and explicitly reuses the same icon-flight contract, move that partial component's common requirements, alternatives and component-only resources to `docs/presentation/components/icon-flight.md`. Both presentations reference it and retain their own trigger/result, sequence, adopted combination and acceptance entry. Item icons already owned by the Art Bible remain references. Update presentation navigation with the shared component and consumers; remove the old component body from `item-added.md`.
