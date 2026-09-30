# Standardizing particle presentation requirements

Describe how the population appears and evolves. Split components when they need materially different lifetimes, spatial behavior or independent control; do not create a subsystem for every visual adjective.

| Topic | Useful requirement description |
| --- | --- |
| Emission and duration | Distinguish an almost simultaneous burst, a short visible emission window and continuous emission. Separate emitter duration from individual particle lifetime and the visible tail after emission stops. |
| Population and motion | State perceived density, spread, direction, speed evolution and size/color/opacity changes as meaningful targets. Exact counts and values can remain proposed until a constraint or trial justifies them. |
| Space and following | Identify origin/region, local versus world relationship, direction reference, whether already-born particles follow the source, and whether a moving target is tracked continuously or captured at trigger time. |
| Repetition and external control | What triggers, pauses, scales or stops emission? On retrigger, does the effect restart, overlap or continue? On cancellation, do existing particles disappear or finish their tails? |
| Rendering and dependencies | Identify visible shape, texture/frame needs, layering, transparency and overlap readability. Put resource specs in this alternative and link shared assets to their owner. |
| Workload and reproducibility | If material, state expected simultaneous instances, visible density or a reproducibility requirement. Leave simulation rate, seed and GPU/custom processing choices to implementation unless the requirement actually fixes them. |

Example: “角色跑动时脚下冒灰，停下就消失” leaves two decisions unresolved: does stopping end new emission while existing dust fades, or remove all dust immediately; and does emitted dust stay on the ground while the character moves away? Resolve the decisions that affect the intended result without demanding all engine parameters.

For sparks around a dissolving object, the surface dissolve and detached particles can share an external progress or trigger while keeping different lifetimes. Specify that relationship and the relevant cancellation behavior; their algorithms and node organization remain implementation work.

Prefer suitable built-in materials and current project capabilities when they meet the semantics. Do not mandate a handwritten particle Shader, a CPU/GPU choice, or a separate Shader conversation during planning. A texture that has not arrived is an explicit dependency of that candidate, not a reason to stop defining its motion or to claim the final effect has been evaluated.
