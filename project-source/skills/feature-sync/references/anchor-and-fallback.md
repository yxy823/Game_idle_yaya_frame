# Anchor recovery and current-document alignment

Use this reference from [feature-sync](../SKILL.md) Stage 0 when the last `revision_log` entry has no usable `synced_at_commit`, or before reusing an anchor for newly admitted GDD or professional sources. The record fields themselves are defined under [Synchronization records](../../../../methodology/02-feature-list-schema.md#synchronization-records) in methodology 02.

## Recover an anchor from history

Inspect planning commits and their actual Product and Feature contents. Choose a verified source state that the relevant plan already reflects, early enough to include all unsynchronized changes to existing work.

The following do not prove source synchronization:

- a commit that merely touches an index or detail file, updates notes or status, or adds an engineering Feature;
- the first appearance of an empty copied index;
- an empty diff from an unverified recent commit.

Later Product planning must not silently advance the baseline for older work.

## Check sources with unknown coverage

A source that predates the anchor can still be unsynchronized. Before reusing an anchor for a GDD or professional source that the anchored synchronization did not cover, establish whether the affected plan actually incorporated them by comparing historical source and plan contents.

When coverage remains unknown, use the authorized current-document alignment below for that affected planned scope, alongside any verified diffs. Read the current GDD and professional sources whose coverage is unknown even when their diff is empty; widening the diff path list alone cannot prove coverage. Report the distinction, and do not advance the anchor as if the unknown history had been checked.

## Offer current-document alignment

If no reliable baseline can be established, disclose the missing historical evidence and offer whole-document alignment of the current sources and the current plan. Continue only within explicit authorization; do not ask again if this concrete scope is already approved.

During Stage 2:

- Read the complete current sources relevant to existing work and compare them with the current plan.
- Report present alignment gaps and unknown history. Do not invent historical additions or removals.
- Use the report title `Current-document alignment (historical baseline unverified; HEAD <hash>)`.
- Skip the unavailable before/after diff. All scope, impact and Stage 3 approval rules still apply, including the deferred planning of later Products.

## Record the revision

For an approved whole-document alignment:

- Use the actually inspected HEAD for both `anchor_commit` and `synced_at_commit`.
- State in `summary` that current alignment established this baseline and that earlier source history is unknown. This records a new comparison point, not a reconstructed historical diff.
- Support each migration with inspected content; unresolved historical claims stay unresolved.
- Do not invent a commit, add tracking fields or rewrite older revisions.

When verified historical differences and sources with unknown coverage are handled together:

- Keep the verified before and after anchors for the known differences.
- Identify in `summary` the sources that were aligned only at the current HEAD, and claim no historical diff for them.
- Support each migration with an actually inspected before or after source. Unresolved source coverage blocks a claim of complete synchronization.
