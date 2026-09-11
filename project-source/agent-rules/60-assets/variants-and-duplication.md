# Asset Variants and Duplication

Distinguish byte duplicates, visual variants, logical identity, and sampling differences.

## Duplicates/variants

- **[MUST]** Do not treat visual similarity alone as proof that two assets are same logical asset.
- **[MUST]** Do not duplicate source assets merely to get different per-use filter/repeat/material sampling behavior when that can be consumer configuration.
- **[MUST]** Share assets when identity/lifecycle/change coupling is actually shared; separate them when independent evolution is required.
- **[MUST]** Generated variants record source and generation pipeline so they can be reproduced.
