# Operational instructions and verification guides

Use this reference for project tool instructions, reproduction guides and procedures someone must carry out. A Godot scene, a gameplay sequence, a Product acceptance scenario or a Feature design is not automatically an operational guide. Keep those documents' own structure and semantics.

## Follow the reader's task

Start with the operation and the conditions that make it relevant. Explain the intended result and the scope of the procedure. Choose headings and detail for this task rather than imposing a fixed section count or another stage system.

Place prerequisites before the first action that needs them. Distinguish an expected branch from a blocker: a user choosing a scene to inspect is a normal step; missing required sample data may block only the check that uses it. Refer to the project workflow for real authorization and acceptance conditions.

For example, instructions for checking a reopened inventory panel might need the actual entry scene, saved-state fixture, input method and state to observe. An unrelated rendering or export procedure does not need those same prerequisites. Use inspected project facts, not this example, to decide the inputs.

Write ordered steps when one result is needed by the next action. Group independent options or conditions together. Each consequential step should make clear what the reader operates, what changes, what result to inspect and how that result affects continuation. Ordinary short actions need no separate result table.

## Describe the actual tool or editor operation

Check the current command entry, help, configuration or editor interface before documenting it. Name the actual script, scene, menu or control; do not invent a helper because its name would make the instructions shorter. Engine-sensitive claims follow the project's version and authority rules.

Where needed to execute safely and reproduce the result, state:

- The working directory and configured executable, with user-supplied values clearly distinguished from literal arguments.
- The specific input scene, resource, data or target being operated on.
- Outputs and side effects, including imports, generated files or changes to user data when the actual operation has them.
- The observable result and where failures or original evidence are recorded.

Keep commands and code identifiers exact while explaining them in `document_language`. Show only commands supported by the current project. The documentation does not authorize running them; execution stays within the user's task and the project's validation rules.

For a procedure that can alter saves or fixtures, identify the data it should use and the protection already required by its owning contract. Do not present a live user save as disposable test data. Describe recovery for the actual failure cases instead of adding a generic reset or cleanup command.

## Match claims to evidence

A verification guide states what is exercised and what each observation can establish. Preserve these distinctions when writing a result:

| Evidence | Limit on the conclusion |
| --- | --- |
| A scene or resource file exists | Existence does not show that it imported, loaded or behaved correctly |
| A parser, import or headless check completed | Report that check's actual coverage; it does not establish displayed layout, interaction or listening quality |
| A recorded test or interaction exercised a case | Name the relevant version, conditions and coverage; do not extend one case to untested states |
| The user accepted a visual or gameplay result | Record the actual accepted scope; a screenshot, automated pass or prepared checklist does not supply that decision |

For a display claim, relevant conditions may include viewport, scaling, locale, resource and input method. For timing or stability, the workload and actual observation period may matter. Include conditions that affect the claim rather than requiring a universal evidence checklist.

Expected output in a procedure is an expectation, not a report that it occurred. Keep supplied summaries separate from original evidence. Preserve failed, skipped and unavailable checks when they qualify the outcome; do not turn an old run into verification of a changed result through wording.

## Explain interruption and completion

At a blocking point, state the missing fact, resource or decision, what remains valid, and where work can resume. Preserve the project's actual distinction between a diagnostic hypothesis, a confirmed cause and a verified repair. Saving a log is not proof of locating a defect.

End with the result this operation establishes and any remaining work. A tool returning zero, a document being saved and a Feature being delivered are different events. Use the owning workflow's completion conditions without adding another approval, report format or testing gate.

Check the changed instructions against their current sources and applicable project checks. Retain unverified runtime claims as gaps when they cannot be checked within the present authorization. A documentation edit does not require repeating unaffected gameplay or tool operations merely to demonstrate that the prose was reorganized.
