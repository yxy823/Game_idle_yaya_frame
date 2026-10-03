# Application Startup

Treat application startup as a production API, and test it without mutating the production main scene for test convenience.

## Startup

- **[REVIEW]** Changing `application/run/main_scene` changes application startup behavior.
- **[MUST]** Do not temporarily change the production main scene setting to run tests, take screenshots or load fixtures.
- **[PREFER]** The main scene owns the bootstrap and composition that application startup needs; it is not an arbitrary dump for global logic.
- **[MUST]** Scenes and modules do not depend on `/root/Main/...` as a contract between modules.
- **[REVIEW]** A custom `main_loop_type` is an architecture-level runtime change and requires validation on the target version.
- **[MUST]** When `application/config/use_custom_user_dir` is `false`, changing `application/config/name` changes the default `user://` directory. Treat existing saves, settings, progression and other user data as a persistence migration, and validate compatibility or an explicit migration path.
- **[MUST]** Do not enable `use_custom_user_dir` automatically to avoid that migration; preserve and validate the project's existing user-data namespace contract.
