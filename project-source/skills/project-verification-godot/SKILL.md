---
name: project-verification-godot
description: Run requested Godot parsing, lint, existing automated tests or a scoped scene check and report actual results. Supports work with or without a Feature; does not implement fixes or establish delivery completion.
---

# Run the requested verification

Establish the requested check, target and permitted runtime actions from the current task. Apply **GDD prerequisite and authority** in `methodology/01-product-doc-structure.md`. Reuse configured tools and still-valid preparation; use [project-environment-godot](../project-environment-godot/SKILL.md) only for an actual environment dependency within the task's authorization.

## Select the matching check

The following paths are project-relative. Read the branch needed for this request, not every verification method.

| Requested result | Authoritative method |
| --- | --- |
| Script parsing or lint | **Direct execution** in `methodology/gdscript-lint.md`, including its required internal scan scope, exit codes and original-output handling |
| Existing Feature tests | **Runtime Test Impact selection** in `methodology/08-testing-strategy.md`, the actual Feature/Registry obligations and the runner contract in `tools/README.md` |
| A specified test suite/component without a Feature | The focused target route in `tools/README.md` and methodology 08; no Feature, plan or completion record is needed |
| Actual startup or a specific scene/resource observation | The requested scene, relevant project engineering rules through `AGENTS.md` and actual configured Godot environment; first-scan instructions in `tools/README.md` only if preparation is missing |

Run only the requested kinds of check, while retaining each method's required scope and existing obligations. A focused diagnostic run does not satisfy a broader delivery requirement. If the requested restriction conflicts with a required method or permission, explain the specific conflict instead of silently weakening the check or expanding the task.

This method does not edit implementation, tests, AC or check policy to obtain a pass. Return failures to the existing owner; diagnosis or repair follows the task's actual authorization. Preserve original results under **Reports and cleanup** in `methodology/09-artifact-lifecycle.md`. Any permitted repository writes follow `agent-rules/00-core/git-worktree-and-commits.md` and the task's commit conditions.

## Report and continue

Report the actual target, commands, exit codes, original evidence paths, result and unexecuted scope. Distinguish a passing check, failure, interruption and the runner's legitimate `not_required` result. Scene startup or automatic tests do not establish actual human acceptance.

When the task also requires importing or repairing automated evidence, use [verification-evidence-godot](../verification-evidence-godot/SKILL.md). Otherwise return the results without manufacturing a completion record. A check-only request can finish with an honestly reported failure; that does not mean the checked work passed. The owning task continues any already authorized work and decides completion under its existing contract, without a new Stage or repeated approval.
